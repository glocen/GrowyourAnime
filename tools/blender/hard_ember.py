"""AR46, Hard's ember in the world: three directions as stand-ins on the real Shade and the Lamplighter, from the
player's camera in the street by day, Normal beside Hard (research's ask, 2026-11-19, 17:02).

  A  the eyes and the mask's cuts in the ember: a Hard map pair for the mask, the cuts painted the picker's bloom and
     the paper's faint glow off, its tint as it is (by day a glow tint on white cuts drew pink, see EMBER)
  B  A, plus cracks lit from within up the coat, a warm core falling to coral, on the cloth only (a second glow: its
     own surface in the game, the body's one EmissiveTint being its type's), and the burst's flame tinted (its
     ImageColor3), the scraps left paper. Research's pick (17:42), its cracks redrawn to research's must-fix
  C  B, plus faint heat at the feet: an ember light low under each, on the paving and the hem, and a few motes

Drawn on the delivered models riding their rigs in the clips the game plays (the Shade's Idle, the Lamplighter's Ready,
its Idle), at the game's glow (Config.Shades: the body 16 in the type's tint, a mask 6 in its warm white; the Brawler
is Red, the Lamplighter Purple and 1.5 a Shade's size), lit as the street's day (LanternRow lighting.json "Day": the
warm sun high behind the camera, the lilac fill), then laid into Faber's day capture of the street in a fight (TR24,
2026-11-16) through the camera that capture was taken with: Roblox's 70 degree view 12.5 studs behind the avatar,
5.5 degrees down (its horizon, measured). Bloom at the game's day threshold. The ember is the picker's (AR42): an
emissive tint whose green and blue are the picker's edge (#FF9A80) over the glow's strength, so the cuts and cracks
draw that edge with red to spare for the bloom (Config.Shades' own note: any green or blue in a tint at 16 lifts it
toward white).

Stand-ins, for judging the direction only: the cracks' pattern (a procedural noise's middle line), the motes, the
light's numbers, the contact shadows. What the game has today is Normal; A to C would be Faber's spawn switch.

  blender -b --factory-startup --python tools/blender/hard_ember.py -- <abs out> shade|keeper|sheet|veins

`shade` and `keeper` each render their layers into <out>/layers (one Blender at a time, for memory); `sheet` lays
them into the capture: <out>/hard_ember_<look>.png, hard_ember_keeper_<look>.png and the sheet hard_ember.png;
`veins` lays the second look, Normal beside B only, into hard_ember_veins.png.
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
import r6rig  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
STILL = REPO / "build" / "scratch" / "faber" / "stills" / "tr24-07-row-fight.jpg"  # TR24, the street by day, a fight
SHADE_CLIPS = REPO / "build" / "handoff" / "Shade" / "clips"
KEEPER_CLIPS = REPO / "build" / "handoff" / "Lamplighter" / "clips"
BURST_ART = REPO / "build" / "handoff" / "Shade" / "fx"

# the capture's camera: Roblox's default view, the avatar at the origin facing -Z, its feet on y 0
W, H = 1920, 876
FOV, ZOOM, PITCH = 70.0, 12.5, 5.5    # degrees (vertical), studs behind the focus, degrees down (the horizon at y 378)
ROOT = r6rig.ROOT_HEIGHT
FOCUS = ROOT + 1.5                    # the avatar's root and the head's offset
F = (H / 2) / math.tan(math.radians(FOV / 2))
_p = math.radians(PITCH)
EYE = Vector((0.0, FOCUS + math.sin(_p) * ZOOM, math.cos(_p) * ZOOM))
FWD = Vector((0.0, -math.sin(_p), -math.cos(_p)))
RIGHT = Vector((1.0, 0.0, 0.0))
UP = Vector((0.0, math.cos(_p), -math.sin(_p)))

# the street's day (lighting.json "Day"): toward the sun, its colour; the fill. Strengths in the contact sheets' units.
SUN_TOWARD = Vector((-0.161, 0.883, 0.441))
SUN, SUN_ENERGY = "#FFE2B8", 3.0
FILL, FILL_STRENGTH = "#8A8496", 0.8
BLOOM = (2.2, 0.3, (8.0, 24.0))       # threshold, intensity, blur sigmas in pixels at 876 high (Bloom: 2.2, 0.3, 24)

# Config.Shades and Definitions.Enemies
SHADE = dict(body="#E80000", body_s=16.0, mask="#FFE2B8", mask_s=6.0, scale=1.0)   # the Brawler: Red
KEEPER = dict(body="#A470F2", body_s=16.0, mask="#FFE2B8", mask_s=6.0, scale=1.5)  # the Lamplighter: Purple, 1.5

# the ember. By day a cut's own white, lit by the sun, mixes into any glow tint: round one's coral tints drew pink, and
# with the paper's faint glow tinted the whole mask blushed. So Hard's mask is a map pair, its tint left as it is: the
# cuts painted the picker's bloom, #E85A44, and the paper's glow off (CUTS). The cracks lie on near-black cloth, so they
# take EMBER as their glow's colour: its green and blue are the picker's edge (#FF9A80) over their strength.
EMBER = "#FF4739"
CUT_HARD = "#E85A44"
# the mask's glow map over this is a cut. The map is encoded (shade_model.encode: light x 2 over 12 x the colour under
# it), so a cut reads 0.19 and the paper about 0.07; on Hard the paper's is dropped
CUTS = 0.13
# the cracks, lit from within: a noise's middle line (a cell network's corners drew round spots, which read as holes),
# one smooth octave stretched tall so they run up from the feet, the hem and the cuffs. Their width is in studs (the
# true distance to the line: a raw |n - 0.5| swelled into teardrops where the noise was flat), at most `width`, shaped
# by a second slow noise (wander, clamped through swell) so each crack is a spindle, tapering to nothing at both ends,
# and narrowing as it rises until gone by the chest (rise, studs up the model). Across it, a warm core CRACK_CORE where
# the line is over `core`, falling to EMBER's coral at its edges. On the coat's dark cloth only: none where the body's
# glow map passes trim, or where the colour map is lighter than the cloth (a panel, a sash, a band).
#   The content check, 17:38: flat red dashes sat too near scratches. Research's pick, 17:42: thin white zigzags read as
#   Watt's arcs, this game's electricity; cracks lit from within, wider, tapering, a warm core, no sharp angle, off the
#   keeper's purple trim
CRACK = dict(scale=1.4, stretch=0.12, detail=0.0, width=0.07, wander=4.0, swell=(0.34, 0.54), core=0.7,
             rise=(2.4, 3.7), strength=7.0,     # rise: gone before the shoulders' tops (4), where a tail drew a tick
             trim=(0.60, 0.72),                 # the glow map: the coat's own glow ramp stays under 0.5, the trim 0.75 up
             cloth=(0.05, 0.065),               # linear tone: both coats' cloth under 0.033 (0.2 sRGB), the next 0.073 up
             seed=(4.3, 1.7, 0.0))              # where the pattern sits
CRACK_CORE = "#FFC680"                # warm amber, the ember's heart
# ImageColor3 on the burst's flame (the charge, the flare, the flame): the picker's lit pair's coral end. The paper
# scraps keep their own cream: tinted, the flesh-toned pieces flying from where the body was could read as parts (the
# content check, 17:38)
BURST_TINT = "#FFB4A0"
# the light low under each (on the hem and legs in the render, on the paving in the lay) and the motes, behind the body
HEAT = dict(colour="#FF8A6A", power=120.0, height=0.4, reach=2.0, ground=1.2, motes=5)

LOOKS = ("Normal", "A", "B", "C")
WHAT = {"Normal": "Normal: the game today",
        "A": "A: the eyes and the mask's cuts in the ember",
        "B": "B: A, plus cracks lit from within up the coat (and the burst's flame)",
        "C": "C: B, plus faint heat at the feet"}
# the street's pack, in Roblox studs from the avatar: (name, x, z, faces toward (x, z), Idle frame). Open paving in
# the capture, clear of the avatar and Rook: two come toward the player, one squares up to Rook.
PACK = (("near", -7.0, -3.0, (0.0, 8.0), 0), ("far", -7.0, -12.0, (0.0, 8.0), 37), ("side", 12.5, -5.0, (3.5, -0.5), 74))
KEEPER_AT = ("keeper", -7.5, -8.0, (0.0, 8.0), 20)
BURST_FRAMES = (27, 29)               # the flare, the flame leaving with the scraps; the body is hidden from 27
COLLAR = (0.0, -0.258, 4.306)         # shade_burst_art.json: the collar at the Burst, right, forward, up from the feet


# --- the camera's sums ----------------------------------------------------------------------------------------------

def project(p):
    """A Roblox point to the capture's pixels (x right, y down) and its depth."""
    d = Vector(p) - EYE
    depth = d.dot(FWD)
    return W / 2 + F * d.dot(RIGHT) / depth, H / 2 - F * d.dot(UP) / depth, depth


def ground_points():
    """Where each pixel's ray meets the paving (y 0): x and z per pixel, NaN above the horizon."""
    ys, xs = np.mgrid[0:H, 0:W].astype(np.float32)
    a, b = (xs - W / 2) / F, (ys - H / 2) / F
    dx = FWD.x + a * RIGHT.x - b * UP.x
    dy = FWD.y + a * RIGHT.y - b * UP.y
    dz = FWD.z + a * RIGHT.z - b * UP.z
    with np.errstate(divide="ignore", invalid="ignore"):
        t = np.where(dy < 0, -EYE.y / dy, np.nan)
    return EYE.x + t * dx, EYE.z + t * dz


def facing(at, toward):
    v = Vector((toward[0] - at[0], 0.0, toward[1] - at[1]))
    return v.normalized()


# --- the scene ------------------------------------------------------------------------------------------------------

def key(rig, path, start=0):
    """A delivered clip on the rig from `start`; its last frame."""
    data = json.loads(path.read_text())
    last = 0
    for frame in data["Frames"]:
        f = round(frame["T"] * data["Fps"])
        last = max(last, f)
        for part, pose in frame["Poses"].items():
            joint = rig.joints.get(part)
            if joint is None:
                continue
            joint.matrix_basis = r6.to_blender(r6.cframe(pose))
            joint.keyframe_insert("location", frame=start + f)
            joint.keyframe_insert("rotation_quaternion", frame=start + f)
    return last


def stand(rig, x, z, toward, scale):
    """The root where the game would put it, unkeyed, so the clip's frames leave it be."""
    if rig.root.animation_data:
        rig.root.animation_data_clear()
    at = Vector((x, ROOT * scale, z))
    m = r6.to_blender(r6.look_at(at, at + facing((x, z), toward)))
    rig.root.matrix_basis = m @ Matrix.Scale(scale, 4)


def light(scene):
    for o in [o for o in scene.objects if o.type in ("LIGHT", "CAMERA")]:
        bpy.data.objects.remove(o)
    data = bpy.data.lights.new("Sun", "SUN")
    data.energy, data.color, data.angle = SUN_ENERGY, rs.srgb(SUN)[:3], math.radians(3.0)
    sun = bpy.data.objects.new("Sun", data)
    sun.rotation_euler = (-r6.point_to_blender(SUN_TOWARD)).to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(sun)
    background = scene.world.node_tree.nodes["Background"]
    background.inputs["Color"].default_value = rs.srgb(FILL)
    background.inputs["Strength"].default_value = FILL_STRENGTH
    camera = r6.fixed_camera(scene, EYE, EYE + FWD * 10, FOV, "Player")
    camera.data.clip_end = 2000
    scene.camera = camera
    for name in ("Floor",):
        if name in bpy.data.objects:
            bpy.data.objects[name].hide_render = True
    heat = bpy.data.lights.new("Heat", "POINT")
    heat.color, heat.energy, heat.shadow_soft_size = rs.srgb(HEAT["colour"])[:3], 0.0, 0.4
    heat.use_shadow = False
    obj = bpy.data.objects.new("Heat", heat)
    scene.collection.objects.link(obj)
    return camera, obj


def glows(materials, body_names):
    """Each glowing surface's tint and strength nodes, and on the body a crack layer over its glow (off until B).
    Returns set(look, colours) for the body and the mask."""
    found = {}
    for m in materials:
        nodes, links = m.node_tree.nodes, m.node_tree.links
        tint = next(n for n in nodes if n.bl_idname == "ShaderNodeMix" and n.blend_type == "MULTIPLY")
        strength = next(n for n in nodes if n.bl_idname == "ShaderNodeMath" and n.operation == "MULTIPLY")
        on = None
        if m.name not in body_names:  # a mask: on Hard, the cuts alone glow
            src = strength.inputs[0].links[0].from_socket
            cut = nodes.new("ShaderNodeMath")
            cut.operation = "GREATER_THAN"
            cut.inputs[1].default_value = CUTS
            links.new(src, cut.inputs[0])
            alone = nodes.new("ShaderNodeMath")
            alone.operation = "MULTIPLY"
            links.new(src, alone.inputs[0])
            links.new(cut.outputs[0], alone.inputs[1])
            pick = nodes.new("ShaderNodeMix")
            pick.data_type = "FLOAT"
            on = nodes.new("ShaderNodeValue")
            on.outputs[0].default_value = 0.0
            links.new(on.outputs[0], pick.inputs[0])
            links.new(src, pick.inputs[2])
            links.new(alone.outputs[0], pick.inputs[3])
            links.new(pick.outputs[0], strength.inputs[0])
            # and the cuts' colour under the glow, for the surface and the glow alike
            bsdf = nodes["Principled BSDF"]
            colour_map = tint.inputs[6].links[0].from_socket
            painted = nodes.new("ShaderNodeMath")
            painted.operation = "MULTIPLY"
            links.new(cut.outputs[0], painted.inputs[0])
            links.new(on.outputs[0], painted.inputs[1])
            under = nodes.new("ShaderNodeMix")
            under.data_type, under.blend_type = "RGBA", "MIX"
            links.new(painted.outputs[0], under.inputs[0])
            links.new(colour_map, under.inputs[6])
            under.inputs[7].default_value = rs.srgb(CUT_HARD)
            links.new(under.outputs[2], bsdf.inputs["Base Color"])
            links.new(under.outputs[2], tint.inputs[6])
        if m.name in body_names:
            bsdf = nodes["Principled BSDF"]
            coord = nodes.new("ShaderNodeTexCoord")
            veins = nodes.new("ShaderNodeTexNoise")
            veins.inputs["Scale"].default_value = CRACK["scale"]
            veins.inputs["Detail"].default_value = CRACK["detail"]
            tall = nodes.new("ShaderNodeVectorMath")
            tall.operation = "MULTIPLY"
            tall.inputs[1].default_value = (1.0, 1.0, CRACK["stretch"])
            links.new(coord.outputs["Object"], tall.inputs[0])
            moved = nodes.new("ShaderNodeVectorMath")
            moved.operation = "ADD"
            moved.inputs[1].default_value = CRACK["seed"]
            links.new(tall.outputs[0], moved.inputs[0])
            links.new(moved.outputs[0], veins.inputs["Vector"])
            off = nodes.new("ShaderNodeMath")
            off.operation = "SUBTRACT"
            off.inputs[1].default_value = 0.5
            links.new(veins.outputs["Fac"], off.inputs[0])
            level = nodes.new("ShaderNodeMath")
            level.operation = "ABSOLUTE"
            links.new(off.outputs[0], level.inputs[0])
            # the true distance to the middle line: |n - 0.5| over the noise's slope (three samples a step apart), so
            # a crack's width is in studs and never swells where the noise is flat (those drew teardrops)
            step = 0.01
            slope = nodes.new("ShaderNodeCombineXYZ")
            for axis in range(3):
                probe = nodes.new("ShaderNodeTexNoise")
                probe.inputs["Scale"].default_value = CRACK["scale"]
                probe.inputs["Detail"].default_value = CRACK["detail"]
                nudge = nodes.new("ShaderNodeVectorMath")
                nudge.operation = "ADD"
                nudge.inputs[1].default_value = tuple(step if a == axis else 0.0 for a in range(3))
                links.new(moved.outputs[0], nudge.inputs[0])
                links.new(nudge.outputs[0], probe.inputs["Vector"])
                diff = nodes.new("ShaderNodeMath")
                diff.operation = "SUBTRACT"
                links.new(probe.outputs["Fac"], diff.inputs[0])
                links.new(veins.outputs["Fac"], diff.inputs[1])
                links.new(diff.outputs[0], slope.inputs[axis])
            steep = nodes.new("ShaderNodeVectorMath")
            steep.operation = "LENGTH"
            links.new(slope.outputs[0], steep.inputs[0])
            steep_ok = nodes.new("ShaderNodeMath")
            steep_ok.operation = "MAXIMUM"
            steep_ok.inputs[1].default_value = 1e-6
            links.new(steep.outputs["Value"], steep_ok.inputs[0])
            per = nodes.new("ShaderNodeMath")
            per.operation = "DIVIDE"
            links.new(level.outputs[0], per.inputs[0])
            links.new(steep_ok.outputs[0], per.inputs[1])
            apart = nodes.new("ShaderNodeMath")
            apart.operation = "MULTIPLY"
            apart.inputs[1].default_value = step
            links.new(per.outputs[0], apart.inputs[0])
            height = nodes.new("ShaderNodeSeparateXYZ")
            links.new(coord.outputs["Object"], height.inputs[0])
            rise = nodes.new("ShaderNodeMapRange")
            rise.inputs["From Min"].default_value, rise.inputs["From Max"].default_value = CRACK["rise"]
            rise.inputs["To Min"].default_value, rise.inputs["To Max"].default_value = 1.0, 0.0
            links.new(height.outputs["Z"], rise.inputs["Value"])
            # the taper: a crack is widest at the hem and narrows to a point as it rises, its width wandering slowly
            wander = nodes.new("ShaderNodeTexNoise")
            wander.inputs["Scale"].default_value, wander.inputs["Detail"].default_value = CRACK["wander"], 0.0
            links.new(moved.outputs[0], wander.inputs["Vector"])
            swell = nodes.new("ShaderNodeMapRange")            # clamped: a crack pinches to nothing at both ends
            swell.inputs["From Min"].default_value, swell.inputs["From Max"].default_value = CRACK["swell"]
            swell.inputs["To Min"].default_value, swell.inputs["To Max"].default_value = 0.0, 1.0
            links.new(wander.outputs["Fac"], swell.inputs["Value"])
            taper = nodes.new("ShaderNodeMath")
            taper.operation = "MULTIPLY"
            links.new(rise.outputs["Result"], taper.inputs[0])
            links.new(swell.outputs["Result"], taper.inputs[1])
            wide = nodes.new("ShaderNodeMath")
            wide.operation = "MULTIPLY"
            wide.inputs[1].default_value = CRACK["width"]
            links.new(taper.outputs[0], wide.inputs[0])
            line = nodes.new("ShaderNodeMapRange")
            line.interpolation_type = "SMOOTHSTEP"
            line.inputs["From Min"].default_value = 0.0
            line.inputs["To Min"].default_value, line.inputs["To Max"].default_value = 1.0, 0.0
            links.new(wide.outputs[0], line.inputs["From Max"])
            links.new(apart.outputs[0], line.inputs["Value"])
            # inside the coat: never on the type's glowing trim (the body's own glow map)
            trim = nodes.new("ShaderNodeMapRange")
            trim.inputs["From Min"].default_value, trim.inputs["From Max"].default_value = CRACK["trim"]
            trim.inputs["To Min"].default_value, trim.inputs["To Max"].default_value = 1.0, 0.0
            links.new(strength.inputs[0].links[0].from_socket, trim.inputs["Value"])
            # and on the coat's dark cloth only: never a panel, a sash, a band or a cuff (the colour map's tone)
            tone = nodes.new("ShaderNodeRGBToBW")
            links.new(tint.inputs[6].links[0].from_socket, tone.inputs[0])
            cloth = nodes.new("ShaderNodeMapRange")
            cloth.inputs["From Min"].default_value, cloth.inputs["From Max"].default_value = CRACK["cloth"]
            cloth.inputs["To Min"].default_value, cloth.inputs["To Max"].default_value = 1.0, 0.0
            links.new(tone.outputs[0], cloth.inputs["Value"])
            # and on the sides only: an end cap (a cuff's face, a shoulder's top) takes the noise unstretched, which drew
            # zig-zags across the keeper's held-out cuff and lone ticks on top (the content check, 17:55)
            facing = nodes.new("ShaderNodeSeparateXYZ")
            links.new(coord.outputs["Normal"], facing.inputs[0])
            level_n = nodes.new("ShaderNodeMath")
            level_n.operation = "ABSOLUTE"
            links.new(facing.outputs["Z"], level_n.inputs[0])
            sides = nodes.new("ShaderNodeMapRange")
            sides.inputs["From Min"].default_value, sides.inputs["From Max"].default_value = 0.4, 0.6
            sides.inputs["To Min"].default_value, sides.inputs["To Max"].default_value = 1.0, 0.0
            links.new(level_n.outputs[0], sides.inputs["Value"])
            gate = nodes.new("ShaderNodeMath")
            gate.operation = "MULTIPLY"
            links.new(trim.outputs["Result"], gate.inputs[0])
            links.new(cloth.outputs["Result"], gate.inputs[1])
            inside = nodes.new("ShaderNodeMath")
            inside.operation = "MULTIPLY"
            links.new(gate.outputs[0], inside.inputs[0])
            links.new(sides.outputs["Result"], inside.inputs[1])
            crack = nodes.new("ShaderNodeMath")
            crack.operation, crack.name = "MULTIPLY", "Crack"     # hard_cut.py bakes these two by name
            links.new(line.outputs["Result"], crack.inputs[0])
            links.new(inside.outputs[0], crack.inputs[1])
            # across a crack: its middle the warm core, falling to coral at its edges
            core = nodes.new("ShaderNodeMapRange")
            core.name = "Core"
            core.interpolation_type = "SMOOTHSTEP"
            core.inputs["From Min"].default_value, core.inputs["From Max"].default_value = CRACK["core"], 1.0
            links.new(line.outputs["Result"], core.inputs["Value"])
            ramp = nodes.new("ShaderNodeMix")
            ramp.data_type, ramp.blend_type = "RGBA", "MIX"
            links.new(core.outputs["Result"], ramp.inputs[0])
            ramp.inputs[6].default_value = rs.srgb(EMBER)
            ramp.inputs[7].default_value = rs.srgb(CRACK_CORE)
            on = nodes.new("ShaderNodeValue")
            on.outputs[0].default_value = 0.0
            shown = nodes.new("ShaderNodeMath")
            shown.operation = "MULTIPLY"
            links.new(crack.outputs[0], shown.inputs[0])
            links.new(on.outputs[0], shown.inputs[1])
            colour = nodes.new("ShaderNodeMix")
            colour.data_type, colour.blend_type = "RGBA", "MIX"
            links.new(shown.outputs[0], colour.inputs[0])
            links.new(tint.outputs[2], colour.inputs[6])
            links.new(ramp.outputs[2], colour.inputs[7])
            links.new(colour.outputs[2], bsdf.inputs["Emission Color"])
            hot = nodes.new("ShaderNodeMath")
            hot.operation = "MULTIPLY"
            hot.inputs[1].default_value = CRACK["strength"]
            links.new(shown.outputs[0], hot.inputs[0])
            most = nodes.new("ShaderNodeMath")
            most.operation = "MAXIMUM"
            links.new(strength.outputs[0], most.inputs[0])
            links.new(hot.outputs[0], most.inputs[1])
            links.new(most.outputs[0], bsdf.inputs["Emission Strength"])
        found[m.name] = (tint, strength, on)

    def wear(look, game):
        hard = look != "Normal"
        for name, (tint, strength, on) in found.items():
            body = name in body_names
            tint.inputs[7].default_value = rs.srgb(game["body"] if body else game["mask"])
            strength.inputs[1].default_value = game["body_s"] if body else game["mask_s"]
            if body:
                on.outputs[0].default_value = 1.0 if look in ("B", "C") else 0.0
            else:
                on.outputs[0].default_value = 1.0 if hard else 0.0
    return wear


def border(scene, x, z, scale, tall):
    """Renders only round the figure: its feet and its top, widened."""
    xs, ys = [], []
    for dx in (-2.2 * scale, 2.2 * scale):
        for y in (0.0, tall * scale):
            px, py, _ = project((x + dx, y, z))
            xs.append(px)
            ys.append(py)
    pad = 30
    r = scene.render
    r.use_border, r.use_crop_to_border = True, False
    r.border_min_x, r.border_max_x = max(min(xs) - pad, 0) / W, min(max(xs) + pad, W) / W
    r.border_min_y, r.border_max_y = 1 - min(max(ys) + pad, H) / H, 1 - max(min(ys) - pad, 0) / H


def render(scene, path):
    """The fighters alone, linear and premultiplied, row 0 the top."""
    r = scene.render
    r.image_settings.file_format, r.image_settings.color_depth = "OPEN_EXR", "32"
    exr = path.with_suffix(".exr")
    r.filepath = str(exr)
    bpy.ops.render.render(write_still=True)
    image = bpy.data.images.load(str(exr))
    data = np.empty(W * H * 4, dtype=np.float32)
    image.pixels.foreach_get(data)
    bpy.data.images.remove(image)
    exr.unlink()
    np.save(path, data.reshape(H, W, 4)[::-1].astype(np.float16))
    print(f"layer {path.name}")


def setup(scene):
    rm.eevee(scene, W, H)
    scene.render.use_stamp = False
    try:
        scene.eevee.taa_render_samples = 32
    except AttributeError:
        pass
    return light(scene)


# --- the burst's pictures, as the game's billboards --------------------------------------------------------------

def burst_material(name, tint):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nodes, links = m.node_tree.nodes, m.node_tree.links
    nodes.clear()
    image = nodes.new("ShaderNodeTexImage")
    image.image = bpy.data.images.load(str(BURST_ART / "shade_burst.png"), check_existing=True)
    image.interpolation = "Linear"
    mix = nodes.new("ShaderNodeMix")
    mix.data_type, mix.blend_type = "RGBA", "MULTIPLY"
    mix.inputs[0].default_value = 1.0
    links.new(image.outputs["Color"], mix.inputs[6])
    mix.inputs[7].default_value = rs.srgb(tint)
    emit = nodes.new("ShaderNodeEmission")
    emit.inputs["Strength"].default_value = 1.0
    links.new(mix.outputs[2], emit.inputs["Color"])
    clear = nodes.new("ShaderNodeBsdfTransparent")
    both = nodes.new("ShaderNodeMixShader")
    links.new(image.outputs["Alpha"], both.inputs[0])
    links.new(clear.outputs[0], both.inputs[1])
    links.new(emit.outputs[0], both.inputs[2])
    out = nodes.new("ShaderNodeOutputMaterial")
    links.new(both.outputs[0], out.inputs["Surface"])
    for attr, value in (("surface_render_method", "BLENDED"), ("blend_method", "BLEND")):
        try:
            setattr(m, attr, value)
        except (AttributeError, TypeError):
            pass
    return m


def billboards(scene, camera, frame, x, z, toward, material):
    """The frame's pictures from shade_burst_art.json, each a quad facing the camera at its place off the collar, in
    `material(what)`'s material."""
    art = json.loads((BURST_ART / "shade_burst_art.json").read_text())
    iw, ih = art["size"]
    bpy.context.view_layer.update()
    look = facing((x, z), toward)
    right = Vector((-look.z, 0.0, look.x))
    up = Vector((0.0, 1.0, 0.0))
    collar = Vector((x, 0.0, z)) + right * COLLAR[0] + look * COLLAR[1] + up * COLLAR[2]
    turn = camera.matrix_world.to_3x3().normalized().to_4x4()
    made = []
    for i, pic in enumerate(art["frames"][str(frame)]):
        at = collar + right * pic["at"][0] + look * pic["at"][1] + up * pic["at"][2]
        w, h = pic["size"][0] * pic["squash"], pic["size"][1]
        mesh = bpy.data.meshes.new(f"Burst{frame}_{i}")
        mesh.from_pydata([(-w / 2, -h / 2, 0), (w / 2, -h / 2, 0), (w / 2, h / 2, 0), (-w / 2, h / 2, 0)], [],
                         [(0, 1, 2, 3)])
        rx, ry, rw, rh = pic["rect"]
        u0, u1, v0, v1 = rx / iw, (rx + rw) / iw, 1 - (ry + rh) / ih, 1 - ry / ih
        uv = mesh.uv_layers.new()
        corners = [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]
        for loop in mesh.loops:
            uv.data[loop.index].uv = corners[loop.vertex_index]
        mesh.materials.append(material(pic["what"]))
        obj = bpy.data.objects.new(mesh.name, mesh)
        obj.matrix_world = (Matrix.Translation(r6.point_to_blender(at)) @ turn @
                            Matrix.Rotation(-math.radians(pic["rotation"]), 4, "Z"))
        obj.visible_shadow = False
        scene.collection.objects.link(obj)
        made.append(obj)
    return made


# --- the two runs ---------------------------------------------------------------------------------------------------

def shade_run(out):
    import shade_clips as sc
    scene, rig, undress, wear_mask, feet = sc.build("Strength")
    wear_mask("Brawler")
    camera, heat = setup(scene)
    last = key(rig, SHADE_CLIPS / "Shade_Idle.json")
    materials = {s.material for o in scene.objects for s in o.material_slots if s.material}
    wear = glows([m for m in materials if m.name in ("Shade_Baked", "Shade_Mask")], {"Shade_Baked"})
    for look in LOOKS:
        wear(look, SHADE)
        for name, x, z, toward, frame in PACK:
            stand(rig, x, z, toward, 1.0)
            heat.data.energy = HEAT["power"] if look == "C" else 0.0
            heat.location = r6.point_to_blender((x, HEAT["height"], z))
            scene.frame_set(frame % last)
            border(scene, x, z, 1.0, 5.6)
            render(scene, out / f"shade_{look}_{name}.npy")
    # the burst: the body's gone from 27, so only the pictures, at the near Shade's place
    heat.data.energy = 0.0
    for o in scene.objects:
        if o.type == "MESH":
            o.hide_render = True
    name, x, z, toward, _ = PACK[0]
    paper = burst_material("BurstPaper", "#FFFFFF")
    for tint, label in (("#FFFFFF", "Normal"), (BURST_TINT, "Hard")):
        fire = burst_material(f"Burst{label}", tint)
        for frame in BURST_FRAMES:
            made = billboards(scene, camera, frame, x, z, toward, lambda what: paper if what == "scrap" else fire)
            border(scene, x, z, 1.6, 8.5)
            render(scene, out / f"burst_{frame}_{label}.npy")
            for o in made:
                bpy.data.objects.remove(o)


def keeper_run(out):
    import lamplighter_clips as lc
    scene, rig, costume, undress, feet, *_ = lc.build(out)
    camera, heat = setup(scene)
    last = key(rig, KEEPER_CLIPS / "Lamplighter_Ready.json")
    materials = {s.material for o in scene.objects for s in o.material_slots if s.material}
    glowing = [m for m in materials if m.name in ("Lamplighter_Body", "Lamplighter_Mask")]
    wear = glows(glowing, {"Lamplighter_Body"})
    name, x, z, toward, frame = KEEPER_AT
    for look in LOOKS:
        wear(look, KEEPER)
        stand(rig, x, z, toward, KEEPER["scale"])
        heat.data.energy = HEAT["power"] * KEEPER["scale"] ** 2 if look == "C" else 0.0
        heat.location = r6.point_to_blender((x, HEAT["height"] * KEEPER["scale"], z))
        scene.frame_set(frame % last)
        border(scene, x, z, KEEPER["scale"] * 1.3, 7.4)
        render(scene, out / f"keeper_{look}.npy")


# --- the sheet --------------------------------------------------------------------------------------------------

def to_linear(c):
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def to_srgb(c):
    c = np.clip(c, 0, 1)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * np.power(c, 1 / 2.4) - 0.055)


def blur(channel, sigma):
    """A Gaussian blur, padded with its edge first (the FFT's blur is circular)."""
    pad = int(math.ceil(3 * sigma))
    padded = np.pad(channel, pad, mode="edge")
    h, w = padded.shape
    fy, fx = np.fft.fftfreq(h)[:, None], np.fft.rfftfreq(w)[None, :]
    kernel = np.exp(-2 * (math.pi * sigma) ** 2 * (fx ** 2 + fy ** 2))
    return np.fft.irfft2(np.fft.rfft2(padded) * kernel, s=(h, w))[pad:-pad, pad:-pad]


def bloom(fighters):
    threshold, intensity, sigmas = BLOOM
    rgb = fighters[..., :3]
    lum = rgb @ np.array([0.2126, 0.7152, 0.0722], np.float32)
    over = rgb * (np.clip(lum - threshold, 0, None) / np.maximum(lum, 1e-4))[..., None]
    glow = np.zeros_like(rgb)
    for sigma in sigmas:
        for ch in range(3):
            glow[..., ch] += blur(over[..., ch], sigma) * 0.5
    return intensity * glow


def lay(backdrop, layers, places, look, gx, gz):
    """The capture with the fighters in it: their contact shadows and, in C, the heat on the paving under the layers;
    the layers far to near; the motes; the bloom of what the fighters add."""
    comp = backdrop.copy()
    shadow_dir = Vector((-SUN_TOWARD.x, 0.0, -SUN_TOWARD.z)).normalized()
    heat_rgb = np.array(rs.srgb(HEAT["colour"])[:3], np.float32)
    for x, z, scale in places:
        # the sun's short shadow from the feet, away from the camera
        ax, az = gx - x, gz - z
        along = np.clip(ax * shadow_dir.x + az * shadow_dir.z, 0, 1.8 * scale)
        dist = np.hypot(ax - along * shadow_dir.x, az - along * shadow_dir.z)
        dark = np.nan_to_num(0.45 * np.exp(-(dist / (0.8 * scale)) ** 2))
        comp[..., :3] *= (1 - dark)[..., None]
        if look == "C":
            r = np.hypot(ax, az)
            lit = np.nan_to_num(HEAT["ground"] * np.exp(-(r / (HEAT["reach"] * scale)) ** 2))
            comp[..., :3] += backdrop[..., :3] * heat_rgb * lit[..., None]
    fighters = np.zeros_like(comp)
    clear = np.ones(comp.shape[:2] + (1,), np.float32)   # how much of the paving shows past the bodies
    for layer in sorted(layers, key=lambda item: -item[0]):
        px = layer[1]
        comp[..., :3] = px[..., :3] + comp[..., :3] * (1 - px[..., 3:])
        fighters[..., :3] += px[..., :3]
        clear *= 1 - px[..., 3:]
    if look == "C":
        rng = np.random.default_rng(46)
        ys, xs = np.mgrid[0:H, 0:W].astype(np.float32)
        mote = np.array(rs.srgb(EMBER)[:3], np.float32)
        for x, z, scale in places:
            for _ in range(HEAT["motes"]):
                a, rad, up = rng.uniform(0, 2 * math.pi), rng.uniform(0.5, 1.2) * scale, rng.uniform(0.1, 1.4) * scale
                px, py, depth = project((x + math.cos(a) * rad, up, z + math.sin(a) * rad))
                size = max(0.06 * F / depth, 0.8)
                d2 = ((xs - px) ** 2 + (ys - py) ** 2) / size ** 2
                spot = (3.0 * np.exp(-d2) + 0.25 * np.exp(-d2 / 9))[..., None] * mote * clear
                comp[..., :3] += spot
                fighters[..., :3] += spot
    comp[..., :3] += bloom(fighters)
    out = np.empty_like(comp)
    out[..., :3], out[..., 3] = to_srgb(comp[..., :3]), 1.0
    return out


def crop(img, x, y, w, h):
    return img[y:y + h, x:x + w].copy()


def sheet_run(out, looks=LOOKS, second=False):
    """The sheet; `second`: the second look, the veins only (Normal and B, no burst), into hard_ember_veins.png."""
    rs.OUT = out
    layers_dir = out / "layers"
    still = rs.load(STILL)
    backdrop = still.copy()
    backdrop[..., :3] = to_linear(still[..., :3])
    gx, gz = ground_points()

    def layer(name):
        return np.load(layers_dir / f"{name}.npy").astype(np.float32)

    pack, keeper = {}, {}
    pack_places = [(x, z, 1.0) for _, x, z, _, _ in PACK]
    _, kx, kz, _, _ = KEEPER_AT
    for look in looks:
        shades = [(project((x, 0, z))[2], layer(f"shade_{look}_{name}")) for name, x, z, _, _ in PACK]
        pack[look] = lay(backdrop, shades, pack_places, look, gx, gz)
        rs.save(pack[look], out / f"hard_ember_{look}.png")
        keeper[look] = lay(backdrop, [(1.0, layer(f"keeper_{look}"))], [(kx, kz, KEEPER["scale"])], look, gx, gz)
        rs.save(keeper[look], out / f"hard_ember_keeper_{look}.png")
    bursts = {}
    for frame in BURST_FRAMES:
        for label in ("Normal", "Hard"):
            bursts[frame, label] = lay(backdrop, [(1.0, layer(f"burst_{frame}_{label}"))], [], "Normal", gx, gz)

    # where to look closer: the near and far Shades, the side one, the keeper, the burst (full-size pixels)
    def box(places, half_w, top, pad=26):
        xs, ys = [], []
        for x, z in places:
            for dx in (-half_w, half_w):
                for y in (0.0, top):
                    px, py, _ = project((x + dx, y, z))
                    xs.append(px)
                    ys.append(py)
        x0, y0 = int(min(xs)) - pad, int(min(ys)) - pad
        return x0, y0, int(max(xs)) + pad - x0, int(max(ys)) + pad - y0

    near = box([(PACK[0][1], PACK[0][2]), (PACK[1][1], PACK[1][2])], 1.6, 5.3)
    side = box([(PACK[2][1], PACK[2][2])], 1.6, 5.3)
    kbox = box([(kx, kz)], 3.2, 10.6)
    bbox = box([(PACK[0][1], PACK[0][2])], 2.2, 8.8)

    half = W // 2, H // 2
    gap, head, label = 24, 120, 30
    zoom = 2
    cols = [half[0], near[2] * zoom, side[2] * zoom, kbox[2]]
    row_h = max(half[1], near[3] * zoom, side[3] * zoom, kbox[3])
    burst_h = 0 if second else label + bbox[3] * zoom
    width = gap + sum(c + gap for c in cols)
    height = head + len(looks) * (label + row_h + gap) + burst_h + 2 * gap + 60
    page = rs.canvas(width, height, rs.rgb("#101117"))
    ink, soft, pale = "#EDE6D6", "#B4AC9C", "#8C8577"
    title = ("AR46'S SECOND LOOK: B'S CRACKS, REDRAWN" if second else "AR46, HARD'S EMBER IN THE WORLD: A, B AND C")
    text = [(gap, 22, 34, title, ink),
            (gap, 70, 16, "The real Brawler and Lamplighter at the game's glow, laid into Faber's day capture of the street "
                          "(TR24) through its own camera. First column: the phone's pixels; then the near pair and the "
                          "side Shade at two times, the keeper at full size.", soft)]
    y = head
    for look in looks:
        text.append((gap, y, 18, WHAT[look], ink))
        y += label
        x = gap
        rs.paste(page, rs.shrink(pack[look], 0.5), x, y)
        x += cols[0] + gap
        for (bx, by, bw, bh), col in ((near, cols[1]), (side, cols[2])):
            big = np.repeat(np.repeat(crop(pack[look], bx, by, bw, bh), zoom, 0), zoom, 1)
            rs.paste(page, big, x, y)
            x += col + gap
        rs.paste(page, crop(keeper[look], *kbox), x, y)
        y += row_h + gap
    if not second:
        text.append((gap, y, 18, "The burst at the near Shade's place, two times: the flare (27), the flame leaving "
                                 "with the scraps (29); Normal, then Hard's tint (B and C)", ink))
        y += label
        x = gap
        for frame in BURST_FRAMES:
            for lbl in ("Normal", "Hard"):
                big = np.repeat(np.repeat(crop(bursts[frame, lbl], *bbox), zoom, 0), zoom, 1)
                rs.paste(page, big, x, y)
                text.append((x + 8, y + 8, 14, f"{frame}, {lbl}", ink))
                x += bbox[2] * zoom + gap
    notes = (f"A: Hard's mask maps, the cuts painted {CUT_HARD}, the paper's glow off, its tint and 6 as today. B: the "
             f"cracks lit from within, a core {CRACK_CORE} falling to {EMBER} at {CRACK['strength']:g}, tapering as "
             f"they rise, off the trim; the burst's flame tinted {BURST_TINT}, the scraps paper."
             + ("" if second else f" C: a light {HEAT['colour']} low under each.")
             + " Stand-ins: the cracks' pattern, the contact shadows.")
    text.append((gap, height - 40, 15, notes, pale))
    rs.paste(page, rs.text_layer(width, height, text), 0, 0)
    name = "hard_ember_veins.png" if second else "hard_ember.png"
    rs.save(page, out / name)
    print(f"wrote {out / name} ({width} by {height})")


def main():
    out = bl.out_dir()
    mode = sys.argv[sys.argv.index("--") + 2] if len(sys.argv) > sys.argv.index("--") + 2 else "sheet"
    layers = out / "layers"
    layers.mkdir(parents=True, exist_ok=True)
    {"shade": lambda: shade_run(layers), "keeper": lambda: keeper_run(layers), "sheet": lambda: sheet_run(out),
     "veins": lambda: sheet_run(out, ("Normal", "B"), second=True)}[mode]()


if __name__ == "__main__":
    main()
