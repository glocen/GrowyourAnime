"""AR69's targets (Scintilla, 2026-11-27): the Shade's fall and the burn as 3D meshes, rendered at the game's own camera
for a paint-over on the game's frames (tools/fx/ar69_sheets.py lays them on).

    blender.exe -b --factory-startup --python tools/blender/ar69_targets.py -- <pose.json> <out_dir> <look> <times> [heading]

<look> is fall_a, fall_b, burn_a or burn_b (build/scratch/scintilla/ar69/directions.md); <times> the seconds after the
fall's Burst beat (or into the burn's loop), comma separated; [heading], for the burn only, renders over a plain stage
from that many degrees round the foe instead of the game's camera. The pose is the game's camera and the bodies' parts,
read in Studio (NL_ScintillaPose): Roblox's Y-up studs, turned here to Blender's Z-up.

Each time writes two EXRs (linear, alpha premultiplied): fx_<t>.exr, the effect alone, the bodies and the floor as
holdouts, and light_<t>.exr, the light the effect throws on white bodies and floor, so the sheet can multiply it into the
frame. The shapes are what the game can build: kit-style meshes with a self-lit texture (layers nested inside each other
for the hot core, the way a SurfaceAppearance on a few MeshParts would), particles as small self-lit specks, a ring on
the floor, a point light. Nothing faces the camera.
"""
from __future__ import annotations

import json
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

# Colours as the game should show them (linear); the core goes past 1 so it clips white and blooms.
CORE = (1.0, 0.92, 0.70)
GOLD = (1.0, 0.56, 0.09)
ORANGE = (1.0, 0.26, 0.045)
RIM = (0.50, 0.075, 0.008)
SMOKE_DAY = ((0.30, 0.27, 0.26), (0.56, 0.53, 0.51))
SMOKE_NIGHT = ((0.07, 0.065, 0.085), (0.17, 0.16, 0.2))
FLOOR_Y = 0.62
SCALE = 0.125  # every light written at an eighth, so ffmpeg, which clips an EXR at 1, reads it whole (x8 back)


def rb(x, y, z) -> Vector:
    """A Roblox point to Blender's axes."""
    return Vector((x, -z, y))


C = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))


def cframe(c) -> Matrix:
    x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = c
    m = Matrix(((r00, r01, r02, x), (r10, r11, r12, y), (r20, r21, r22, z), (0, 0, 0, 1)))
    return C @ m


def ease_out(u, p=2.0):
    u = min(max(u, 0.0), 1.0)
    return 1 - (1 - u) ** p


def ease_in(u, p=2.0):
    u = min(max(u, 0.0), 1.0)
    return u ** p


def span(t, a, b):
    return min(max((t - a) / (b - a), 0.0), 1.0)


def mix(a, b, u):
    return tuple(x + (y - x) * u for x, y in zip(a, b))


# --- the scene -------------------------------------------------------------------------------------------------------

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.film_transparent = True
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.render.image_settings.file_format = "OPEN_EXR"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "16"
    scene.eevee.taa_render_samples = 24
    world = bpy.data.worlds.new("World")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0, 0, 0, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.0
    scene.world = world
    return scene


def collection(name):
    col = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(col)
    return col


def link(obj, col):
    col.objects.link(obj)
    return obj


def mesh_object(name, bm, col, mat=None):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    if mat:
        me.materials.append(mat)
    obj = bpy.data.objects.new(name, me)
    return link(obj, col)


def white_mat():
    m = bpy.data.materials.new("White")
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (1, 1, 1, 1)
    bsdf.inputs["Roughness"].default_value = 1.0
    return m


def grey_mat():
    m = bpy.data.materials.new("Stage")
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = (0.035, 0.035, 0.045, 1)
    ramp.color_ramp.elements[1].position = 1.0
    ramp.color_ramp.elements[1].color = (0.11, 0.11, 0.13, 1)
    nt.links.new(geo.outputs["Normal"], sep.inputs[0])
    nt.links.new(sep.outputs["Z"], ramp.inputs[0])
    em.inputs["Strength"].default_value = SCALE
    nt.links.new(ramp.outputs[0], em.inputs["Color"])
    nt.links.new(em.outputs[0], out.inputs["Surface"])
    return m


def box(name, size, matrix, col, mat=None):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
    obj = mesh_object(name, bm, col, mat)
    obj.matrix_world = matrix
    return obj


def camera_from(pose, scene, width, height):
    cam = bpy.data.cameras.new("Game")
    cam.sensor_fit = "VERTICAL"
    cam.angle_y = math.radians(pose["FOV"])
    cam.clip_start, cam.clip_end = 0.1, 1000
    obj = bpy.data.objects.new("Game", cam)
    scene.collection.objects.link(obj)
    obj.matrix_world = cframe(pose["Camera"])
    scene.camera = obj
    scene.render.resolution_x, scene.render.resolution_y = width, height
    scene.render.resolution_percentage = 100
    return obj


# --- materials for the light -------------------------------------------------------------------------------------------

def flame_mat(name, colour, strength, opacity, tip_fade=0.0, foot_fade=0.0):
    """A self-lit layer: one colour, its opacity, faded toward its tip (V = 1) and foot (V = 0) when asked, the way a
    texture's alpha would. Front faces only, as a MeshPart that isn't DoubleSided."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.surface_render_method = "BLENDED"
    m.use_backface_culling = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (*colour, 1)
    em.inputs["Strength"].default_value = strength * SCALE
    tr = nt.nodes.new("ShaderNodeBsdfTransparent")
    mixer = nt.nodes.new("ShaderNodeMixShader")
    alpha = opacity
    if tip_fade or foot_fade:
        uv = nt.nodes.new("ShaderNodeUVMap")
        sep = nt.nodes.new("ShaderNodeSeparateXYZ")
        nt.links.new(uv.outputs[0], sep.inputs[0])
        ramp = nt.nodes.new("ShaderNodeValToRGB")
        els = ramp.color_ramp.elements
        els[0].position, els[0].color = 0.0, ((0, 0, 0, 1) if foot_fade else (1, 1, 1, 1))
        els[1].position, els[1].color = 1.0, ((0, 0, 0, 1) if tip_fade else (1, 1, 1, 1))
        if foot_fade:
            e = els.new(foot_fade)
            e.color = (1, 1, 1, 1)
        if tip_fade:
            e = els.new(1.0 - tip_fade)
            e.color = (1, 1, 1, 1)
        nt.links.new(sep.outputs["Y"], ramp.inputs[0])
        mul = nt.nodes.new("ShaderNodeMath")
        mul.operation = "MULTIPLY"
        mul.inputs[1].default_value = opacity
        nt.links.new(ramp.outputs[0], mul.inputs[0])
        nt.links.new(mul.outputs[0], mixer.inputs[0])
    else:
        mixer.inputs[0].default_value = alpha
    nt.links.new(tr.outputs[0], mixer.inputs[1])
    nt.links.new(em.outputs[0], mixer.inputs[2])
    nt.links.new(mixer.outputs[0], out.inputs["Surface"])
    return m


def smoke_mat(name, tones, opacity):
    """Smoke in two tones, lit from above (an anime puff): not self-lit, the dark side under."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.surface_render_method = "BLENDED"
    m.use_backface_culling = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(geo.outputs["Normal"], sep.inputs[0])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "CONSTANT"
    els = ramp.color_ramp.elements
    els[0].position, els[0].color = 0.0, (*tones[0], 1)
    els[1].position, els[1].color = 0.55, (*tones[1], 1)
    nt.links.new(sep.outputs["Z"], ramp.inputs[0])
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Strength"].default_value = SCALE
    nt.links.new(ramp.outputs[0], em.inputs["Color"])
    tr = nt.nodes.new("ShaderNodeBsdfTransparent")
    mixer = nt.nodes.new("ShaderNodeMixShader")
    # soft at its outline, so it reads as a puff and not a solid lump
    lw = nt.nodes.new("ShaderNodeLayerWeight")
    lw.inputs["Blend"].default_value = 0.5
    inv = nt.nodes.new("ShaderNodeMath")
    inv.operation = "SUBTRACT"
    inv.inputs[0].default_value = 1.0
    nt.links.new(lw.outputs["Facing"], inv.inputs[1])
    pw = nt.nodes.new("ShaderNodeMath")
    pw.operation = "POWER"
    pw.inputs[1].default_value = 1.6
    nt.links.new(inv.outputs[0], pw.inputs[0])
    op = nt.nodes.new("ShaderNodeMath")
    op.operation = "MULTIPLY"
    op.inputs[1].default_value = opacity
    nt.links.new(pw.outputs[0], op.inputs[0])
    nt.links.new(op.outputs[0], mixer.inputs[0])
    nt.links.new(tr.outputs[0], mixer.inputs[1])
    nt.links.new(em.outputs[0], mixer.inputs[2])
    nt.links.new(mixer.outputs[0], out.inputs["Surface"])
    return m


def ring_mat(name, colour, strength, opacity, inner_soft=0.0, outer_soft=0.6):
    """A ring of light on the floor: its band bright at the inner edge, soft to the outer (U across the band)."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.surface_render_method = "BLENDED"
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    uv = nt.nodes.new("ShaderNodeUVMap")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(uv.outputs[0], sep.inputs[0])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    els = ramp.color_ramp.elements
    els[0].position, els[0].color = 0.0, ((0, 0, 0, 1) if inner_soft else (1, 1, 1, 1))
    els[1].position, els[1].color = 1.0, (0, 0, 0, 1)
    e = els.new(max(inner_soft, 0.02))
    e.color = (1, 1, 1, 1)
    e = els.new(1 - outer_soft)
    e.color = (1, 1, 1, 1)
    nt.links.new(sep.outputs["X"], ramp.inputs[0])
    mul = nt.nodes.new("ShaderNodeMath")
    mul.operation = "MULTIPLY"
    mul.inputs[1].default_value = opacity
    nt.links.new(ramp.outputs[0], mul.inputs[0])
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (*colour, 1)
    em.inputs["Strength"].default_value = strength * SCALE
    tr = nt.nodes.new("ShaderNodeBsdfTransparent")
    mixer = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(mul.outputs[0], mixer.inputs[0])
    nt.links.new(tr.outputs[0], mixer.inputs[1])
    nt.links.new(em.outputs[0], mixer.inputs[2])
    nt.links.new(mixer.outputs[0], out.inputs["Surface"])
    return m


def across_mat(name, opacity, cool=0.0, tip_fade=0.3, foot_fade=0.0, hot=1.0):
    """The kit's fire across a ribbon (fx_fire's way, B1's finish): hard steps from a red rim through orange and gold to
    a white core down the middle (U across, V along), the core narrowing toward the tip, so crossed ribbons read as one
    flame from any side. `cool` (0 to 1) shifts every step one toward the rim as it dies; `hot` scales its light.
    Double-sided, as the MeshPart would be."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.surface_render_method = "BLENDED"
    m.use_backface_culling = False
    nt = m.node_tree
    nt.nodes.clear()
    L = nt.links.new
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    uv = nt.nodes.new("ShaderNodeUVMap")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    L(uv.outputs[0], sep.inputs[0])

    def math_node(op, a=None, b=None):
        n = nt.nodes.new("ShaderNodeMath")
        n.operation = op
        for i, v in enumerate((a, b)):
            if v is None:
                continue
            if isinstance(v, (int, float)):
                n.inputs[i].default_value = v
            else:
                L(v, n.inputs[i])
        return n.outputs[0]

    d = math_node("ABSOLUTE", math_node("SUBTRACT", math_node("MULTIPLY", sep.outputs["X"], 2.0), 1.0))
    narrow = math_node("SUBTRACT", 1.0, math_node("MULTIPLY", sep.outputs["Y"], 0.5))
    dd = math_node("DIVIDE", d, narrow)                      # across, the core narrowing toward the tip
    steps = [(0.0, CORE), (0.13, GOLD), (0.38, ORANGE), (0.76, RIM)]
    ladder = [c for _, c in steps]
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "CONSTANT"
    els = ramp.color_ramp.elements
    for i, (pos, _) in enumerate(steps):
        k = min(i + cool * 1.6, len(ladder) - 1)
        lo = int(k)
        c = mix(ladder[lo], ladder[min(lo + 1, len(ladder) - 1)], k - lo)
        e = els[i] if i < 2 else els.new(pos)
        e.position = pos
        e.color = (*c, 1)
    L(dd, ramp.inputs[0])
    # its light: the core and the gold hotter than the rest (past 1, so they clip white and bloom)
    core = math_node("LESS_THAN", dd, 0.13)
    gold = math_node("LESS_THAN", dd, 0.38)
    glow = math_node("MULTIPLY", math_node("ADD", math_node("ADD", 1.0, math_node("MULTIPLY", core, 1.8 * (1 - cool))),
                                           math_node("MULTIPLY", gold, 0.5)), 1.3 * hot * SCALE)
    em = nt.nodes.new("ShaderNodeEmission")
    L(ramp.outputs[0], em.inputs["Color"])
    L(glow, em.inputs["Strength"])
    # its alpha: inside the ribbon's drawn edge, faded at the tip (and the foot when asked), times its opacity
    inside = math_node("LESS_THAN", dd, 1.0)
    fade = nt.nodes.new("ShaderNodeValToRGB")
    fe = fade.color_ramp.elements
    fe[0].position, fe[0].color = 0.0, ((0, 0, 0, 1) if foot_fade else (1, 1, 1, 1))
    fe[1].position, fe[1].color = 1.0, (0, 0, 0, 1)
    if foot_fade:
        fe.new(foot_fade).color = (1, 1, 1, 1)
    fe.new(1.0 - tip_fade).color = (1, 1, 1, 1)
    L(sep.outputs["Y"], fade.inputs[0])
    alpha = math_node("MULTIPLY", math_node("MULTIPLY", inside, fade.outputs[0]), opacity)
    tr = nt.nodes.new("ShaderNodeBsdfTransparent")
    mixer = nt.nodes.new("ShaderNodeMixShader")
    L(alpha, mixer.inputs[0])
    L(tr.outputs[0], mixer.inputs[1])
    L(em.outputs[0], mixer.inputs[2])
    L(mixer.outputs[0], out.inputs["Surface"])
    return m


def glow_mat(name, colour, strength):
    """A soft round glow added to what's behind (the kit's fx_glow on one particle at LightEmission 1)."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.surface_render_method = "BLENDED"
    m.use_backface_culling = False
    nt = m.node_tree
    nt.nodes.clear()
    L = nt.links.new
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    uv = nt.nodes.new("ShaderNodeUVMap")
    off = nt.nodes.new("ShaderNodeVectorMath")
    off.operation = "SUBTRACT"
    off.inputs[1].default_value = (0.5, 0.5, 0.0)
    L(uv.outputs[0], off.inputs[0])
    length = nt.nodes.new("ShaderNodeVectorMath")
    length.operation = "LENGTH"
    L(off.outputs[0], length.inputs[0])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    els = ramp.color_ramp.elements
    els[0].position, els[0].color = 0.0, (1, 1, 1, 1)
    els[1].position, els[1].color = 0.5, (0, 0, 0, 1)
    e = els.new(0.18)
    e.color = (0.35, 0.35, 0.35, 1)
    L(length.outputs["Value"], ramp.inputs[0])
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (*colour, 1)
    mul = nt.nodes.new("ShaderNodeMath")
    mul.operation = "MULTIPLY"
    mul.inputs[1].default_value = strength * SCALE
    L(ramp.outputs[0], mul.inputs[0])
    L(mul.outputs[0], em.inputs["Strength"])
    tr = nt.nodes.new("ShaderNodeBsdfTransparent")
    add = nt.nodes.new("ShaderNodeAddShader")
    L(tr.outputs[0], add.inputs[0])
    L(em.outputs[0], add.inputs[1])
    L(add.outputs[0], out.inputs["Surface"])
    return m


# --- shapes (Blender's axes) ------------------------------------------------------------------------------------------

EYE = Vector((0, 0, 0))  # the camera's place, for what faces it (set by main)


def lumpy_sphere(radius, seed, lumps=0.18, subdiv=3, squash=1.0):
    rnd = random.Random(seed)
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=1.0)
    centres = [Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1))).normalized() for _ in range(9)]
    weights = [rnd.uniform(0.5, 1.0) for _ in centres]
    for v in bm.verts:
        d = v.co.normalized()
        bump = sum(w * max(0.0, d.dot(c)) ** 6 for c, w in zip(centres, weights))
        r = radius * (1 + lumps * (bump - 0.35))
        v.co = Vector((d.x * r, d.y * r, d.z * r * squash))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def flame_ball(seed, licks, blow):
    """A ball with pointed flame licks pulled out of it, most of them up or along the blow, irregular in count and
    spacing (no wheel)."""
    rnd = random.Random(seed)
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=4, radius=1.0)
    up = Vector((0, 0, 1))
    tips = []
    for _ in range(rnd.randint(6, 9)):
        d = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-0.3, 1.0)))
        d = (d.normalized() + up * rnd.uniform(0.4, 1.1) + blow * rnd.uniform(0.0, 0.9)).normalized()
        tips.append((d, rnd.uniform(0.55, 1.0), math.radians(rnd.uniform(16, 28))))
    for v in bm.verts:
        d = v.co.normalized()
        lick = 0.0
        for c, w, width in tips:
            a = math.acos(max(-1.0, min(1.0, d.dot(c))))
            lick = max(lick, w * max(0.0, 1 - a / width) ** 1.6)
        r = 1 + licks * lick
        if d.z < -0.5:
            r *= 0.85 + 0.15 * (1 + d.z) / 0.5
        v.co = d * r
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def ribbons(path, width_fn, count=3, turn=0.0):
    """Crossed ribbons along a path, `count` strips turned evenly round it, each width_fn(s) wide (s 0 at the foot, 1 at
    the tip). UV: U across, V along. The fire's mesh: from any side one ribbon is broad to the camera."""
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    n = len(path)
    frames = []
    prev = None
    for i in range(n):
        t = (path[min(i + 1, n - 1)] - path[max(i - 1, 0)]).normalized()
        if prev is None:
            ref = Vector((0, 0, 1)) if abs(t.z) < 0.9 else Vector((1, 0, 0))
            a = t.cross(ref).normalized()
        else:
            a = (prev - t * prev.dot(t)).normalized()  # carried along, so the ribbon doesn't flip
        b = t.cross(a).normalized()
        frames.append((a, b))
        prev = a
    for r in range(count):
        ang = math.pi * r / count + turn
        left, right = [], []
        for i, p in enumerate(path):
            s = i / (n - 1)
            a, b = frames[i]
            side = a * math.cos(ang) + b * math.sin(ang)
            w = width_fn(s) / 2
            left.append(bm.verts.new(p - side * w))
            right.append(bm.verts.new(p + side * w))
        for i in range(n - 1):
            f = bm.faces.new((left[i], right[i], right[i + 1], left[i + 1]))
            for loop, co in zip(f.loops, ((0, i / (n - 1)), (1, i / (n - 1)), (1, (i + 1) / (n - 1)), (0, (i + 1) / (n - 1)))):
                loop[uv].uv = co
    return bm


def tongue_width(width, foot=0.55):
    """A lick's width along it: a round foot, widest a quarter up, to a point."""
    def w(s):
        grow = foot + (1 - foot) * math.sin(min(s / 0.25, 1.0) * math.pi / 2)
        return width * grow * (1 - s) ** 0.85
    return w


def curve(foot, direction, length, bend, n=14):
    """A curve from foot along direction, bent by `bend` (a vector) toward the tip."""
    return [foot + direction * (length * (i / (n - 1))) + bend * ((i / (n - 1)) ** 2) for i in range(n)]


def shard(seed, size):
    rnd = random.Random(seed)
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=0, radius=1.0)
    stretch = Vector((rnd.uniform(0.5, 0.8), rnd.uniform(1.1, 1.6), rnd.uniform(0.25, 0.45)))
    for v in bm.verts:
        v.co = Vector((v.co.x * stretch.x, v.co.y * stretch.y, v.co.z * stretch.z)) * size * rnd.uniform(0.75, 1.2)
    rot = Matrix.Rotation(rnd.uniform(0, 6.28), 4, Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), 1)).normalized())
    bmesh.ops.transform(bm, matrix=rot, verts=bm.verts)
    return bm


def speck(size):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=size)
    return bm


def facing_disc(size):
    """A square facing +Z with UVs (turned to the camera by the caller): one glow particle."""
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    vs = [bm.verts.new((x * size, y * size, 0)) for x, y in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    f = bm.faces.new(vs)
    for loop, co in zip(f.loops, ((0, 0), (1, 0), (1, 1), (0, 1))):
        loop[uv].uv = co
    return bm


def glow(name, centre, radius, colour, strength, col):
    obj = mesh_object(name, facing_disc(radius), col, glow_mat(name, colour, strength))
    obj.location = centre
    obj.rotation_euler = (EYE - centre).to_track_quat("Z", "Y").to_euler()
    return obj


def annulus(inner, outer, segs=96):
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.new("UVMap")
    ins, outs = [], []
    for i in range(segs):
        a = 2 * math.pi * i / segs
        ins.append(bm.verts.new((math.cos(a) * inner, math.sin(a) * inner, 0)))
        outs.append(bm.verts.new((math.cos(a) * outer, math.sin(a) * outer, 0)))
    for i in range(segs):
        j = (i + 1) % segs
        face = bm.faces.new((ins[i], outs[i], outs[j], ins[j]))
        for loop, uv in zip(face.loops, ((0, 0), (1, 0), (1, 1), (0, 1))):
            loop[uv_layer].uv = uv
    for f in bm.faces:
        f.normal_update()
        if f.normal.z < 0:
            f.normal_flip()
    return bm


def spiral_path(foot, radius_fn, height, turns, phase, lo, hi, rows=48):
    """Points of a strand wound up round an upright axis from `foot`, from lo to hi of its height."""
    pts = []
    for i in range(rows + 1):
        s = lo + (hi - lo) * i / rows
        a = phase + 2 * math.pi * turns * s
        r = radius_fn(s)
        pts.append(foot + Vector((math.cos(a) * r, math.sin(a) * r, height * s)))
    return pts


# --- the looks, at a time ---------------------------------------------------------------------------------------------

class Pose:
    def __init__(self, pose):
        self.raw = pose
        parts = {p["N"]: p for p in pose["Bodies"]["brawler_75"]}
        torso = parts["Shade_Torso"]["C"]
        self.torso = Vector(torso[:3])                       # Roblox
        r = torso[3:]
        self.look = Vector((-r[2], -r[5], -r[8]))            # the foe's facing, Roblox
        self.right = Vector((r[0], r[3], r[6]))
        self.up = Vector((r[1], r[4], r[7]))
        rook = {p["N"]: p for p in pose["Bodies"]["Lead_573369515"]}
        rt = Vector(rook["Rook_Torso"]["C"][:3])
        blow = self.torso - rt
        blow.y = 0
        self.blow = blow.normalized()                         # the defeating blow's way, Roblox, flat


def to_bl(v: Vector) -> Vector:
    return rb(v.x, v.y, v.z)


def dir_bl(v: Vector) -> Vector:
    return Vector((v.x, -v.z, v.y))


def lick(name, path, width, opacity, col, cool=0.0, count=3, tip_fade=0.3, foot_fade=0.0, hot=1.0, foot=0.55):
    bm = ribbons(path, tongue_width(width, foot), count, turn=sum(map(ord, name)) % 7 * 0.2)
    return mesh_object(name, bm, col, across_mat(name, opacity, cool, tip_fade, foot_fade, hot))


def fall_a(t, pose, col, night, lights):
    """The break: a white flash in a burst of flame licks thrown along the blow, a thin flame body round it, gold chips,
    a puff, a ring of light on the floor."""
    centre = to_bl(pose.torso + Vector((0, 0.2, 0)))
    blow = dir_bl(pose.blow)
    up = Vector((0, 0, 1))
    side = blow.cross(up).normalized()
    grow = ease_out(span(t, 0.0, 4 / 60), 2.5)
    cool = span(t, 0.08, 0.32)
    # the ball: a flame-ball mesh swelling to 1.6 times the body (its outline), a glow before it toward the camera (its
    # white-hot middle: the kit's fx_glow on one particle, ZOffset toward the camera), cooling and rising as it goes
    k = 2.35 * max(grow, 0.05) * (1.0 + 0.22 * ease_out(span(t, 4 / 60, 0.35), 2))
    lift = ease_out(span(t, 0.06, 0.4), 1.6)
    middle = centre + blow * 0.35 + up * (1.1 * lift)
    op = 0.95 * (1.0 - ease_in(span(t, 0.16, 0.36), 1.2)) * ease_out(span(t, 0, 1 / 60))
    if op > 0.01:
        obj = mesh_object("ball", flame_ball(5, 0.55, blow), col,
                          flame_mat("ball", mix(ORANGE, RIM, 0.1 + 0.7 * cool), 1.3, op))
        obj.location = middle
        obj.scale = (k, k, k * 0.95)
        rim = mesh_object("rim", flame_ball(9, 0.8, blow), col,
                          flame_mat("rim", mix(ORANGE, RIM, 0.65 + 0.35 * cool), 1.15, 0.6 * op))
        rim.location = middle + up * 0.15
        rim.scale = (k * 1.14, k * 1.14, k * 1.1)
    hot = (1.0 - ease_in(span(t, 0.03, 0.22), 1.2)) * ease_out(span(t, 0, 1 / 60))
    if hot > 0.01:
        toward = (EYE - middle).normalized()
        glow("heart", middle + toward * (k * 1.2), k * (0.9 - 0.3 * span(t, 0.05, 0.22)), mix(CORE, GOLD, cool),
             2.4 * hot, col)
    flash = (1.0 - ease_in(span(t, 0.02, 0.1), 1.3)) * ease_out(span(t, 0, 2 / 60))
    if flash > 0.01:
        glow("flash", centre + (EYE - centre).normalized() * 3.0, 3.3, CORE, 1.0 * flash, col)
    # licks off its top: a few, broad, rising (crossed ribbons with the kit's fire across them)
    rnd = random.Random(17)
    for n in range(6):
        d = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(0.6, 1.4)))
        d = (d.normalized() + blow * rnd.uniform(0.1, 0.5)).normalized()
        length = rnd.uniform(1.6, 2.6)
        width = rnd.uniform(1.5, 2.1)
        delay = rnd.uniform(1 / 60, 3 / 60)
        u = ease_out(span(t, delay, delay + 5 / 60), 2.2)
        fade = 1.0 - ease_in(span(t, 0.16 + delay, 0.38 + delay), 1.3)
        if u <= 0 or fade <= 0.01:
            continue
        foot = middle + d * (k * 0.75)
        path = curve(foot, d, length * u * (1 + 0.3 * lift), up * (0.5 * length * u))
        lick(f"lick{n}", path, width * u * (1 - 0.4 * span(t, 0.14, 0.38)), 0.97 * fade, col, cool, hot=1.1, foot=0.75)
    # spikes, thrown further along the blow: few, thin, quick
    rnd = random.Random(11)
    for n in range(6):
        a = rnd.uniform(-0.9, 0.9)
        e = rnd.uniform(-0.2, 0.8)
        d = ((blow * math.cos(a) + side * math.sin(a)) * math.cos(e) + up * math.sin(e)).normalized()
        length = rnd.uniform(2.4, 3.8)
        delay = rnd.uniform(0, 1.5 / 60)
        u = ease_out(span(t, delay, delay + 4 / 60), 2.2)
        fade = 1.0 - ease_in(span(t, 0.07 + delay, 0.18 + delay), 1.4)
        if u <= 0 or fade <= 0.01:
            continue
        foot = centre + d * (1.6 + 2.0 * span(t, 0.03, 0.2))
        path = curve(foot, d, length * u, up * (0.4 * u))
        lick(f"spike{n}", path, rnd.uniform(0.4, 0.6) * (1 - 0.5 * span(t, 0.05, 0.18)), fade, col, cool, count=2,
             hot=1.3, foot=0.8)
    # chips: small faceted shards of light, flung out with the blow, falling, gold cooling to orange, gone in the air
    rnd = random.Random(23)
    for n in range(16):
        a = rnd.uniform(-1.5, 1.5)
        e = rnd.uniform(0.1, 1.0)
        d = ((blow * math.cos(a) + side * math.sin(a)) * math.cos(e) + up * math.sin(e)).normalized()
        speed = rnd.uniform(9, 17)
        start = rnd.uniform(0, 2 / 60)
        life = rnd.uniform(0.42, 0.62)
        size = rnd.uniform(0.16, 0.3)
        tt = t - start
        if tt <= 0 or tt > life:
            continue
        drag = (1 - math.exp(-2.2 * tt)) / 2.2
        p = centre + d * (1.0 + speed * drag) + up * (-11.0 * tt * tt * 0.5)
        if p.z < FLOOR_Y + 0.4:
            continue
        u = tt / life
        colour = mix(CORE, GOLD, min(u / 0.3, 1)) if u < 0.3 else mix(GOLD, ORANGE, (u - 0.3) / 0.7)
        op = 1.0 - ease_in(span(u, 0.55, 1.0), 1.2)
        obj = mesh_object(f"chip{n}", shard(100 + n, size * (1 - 0.4 * u)), col, flame_mat(f"chip{n}", colour, 2.2, op))
        obj.location = p
        obj.rotation_euler = (tt * 14 + n, tt * 9, n)
    # the puff: dark lumps rising off the top as the fire goes
    tones = SMOKE_NIGHT if night else SMOKE_DAY
    for n in range(5):
        start = 0.14 + 0.025 * n
        u = span(t, start, start + 0.55)
        if u <= 0 or u >= 1:
            continue
        rnd2 = random.Random(40 + n)
        off = Vector((rnd2.uniform(-1.2, 1.2), rnd2.uniform(-1.2, 1.2), 0)) + blow * 0.4
        r = (1.0 + 0.5 * rnd2.random()) * (0.7 + 0.9 * ease_out(u, 2))
        op = 0.85 * (1.0 - ease_in(u, 1.6)) * ease_out(span(t, start, start + 0.06))
        obj = mesh_object(f"puff{n}", lumpy_sphere(1.0, 60 + n, lumps=0.25, subdiv=2), col, smoke_mat(f"puff{n}", tones, op))
        obj.location = centre + off + up * (1.6 + 3.2 * ease_out(u, 1.8))
        obj.scale = (r, r, r * 0.85)
    # the ring of light on the floor
    u = span(t, 1 / 60, 0.36)
    if 0 < u < 1:
        r = 1.0 + 5.5 * ease_out(u, 2.6)
        band = 0.55 + 0.9 * u
        obj = mesh_object("ring", annulus(max(r - band, 0.1), r), col,
                          ring_mat("ring", GOLD, 1.8, 1.0 - ease_in(u, 1.5), 0.0, 0.75))
        obj.location = to_bl(Vector((pose.torso.x, FLOOR_Y + 0.03, pose.torso.z)))
    lights.append((centre + up * 0.4, ORANGE, 900 * (ease_out(span(t, 0, 3 / 60)) - 0.92 * ease_in(span(t, 0.08, 0.5), 1.2))))


def fall_b(t, pose, col, night, lights):
    """The rise: a pillar of fire where the body stood, two strands of flame wound up out of it to the frame's top,
    embers, a ring of light, a puff where the pillar's top breaks."""
    foot = to_bl(Vector((pose.torso.x, FLOOR_Y, pose.torso.z)))
    up = Vector((0, 0, 1))
    snap = ease_out(span(t, 0, 2 / 60), 2)
    cool = span(t, 0.15, 0.45)
    flash = (1.0 - ease_in(span(t, 0.02, 0.14), 1.3)) * snap
    if flash > 0.01:
        glow("flash", foot + up * 2.6, 3.4, CORE, 2.6 * flash, col)
    # the pillar: crossed ribbons, past a body's height at once, then thinning and gone
    if snap > 0:
        height = 8.0 + 5.0 * ease_out(span(t, 2 / 60, 0.22), 2)
        thin = 1.0 - 0.7 * ease_in(span(t, 0.12, 0.42), 1.2)
        fade = 1.0 - ease_in(span(t, 0.22, 0.45), 1.3)
        if fade > 0.01:
            path = [foot + up * (height * snap * i / 15) for i in range(16)]
            obj = mesh_object("pillar", ribbons(path, lambda s: 3.0 * thin * (1.25 - 0.45 * min(s / 0.2, 1)) * (1 - s ** 2.5), 3),
                              col, across_mat("pillar", 0.95 * fade, cool, tip_fade=0.4, hot=1.25))
    # the strands: two, climbing to the frame's top in 0.3 s, then burning off from the foot
    climb = ease_out(span(t, 0.5 / 60, 0.3), 2.2)
    burn = ease_in(span(t, 0.26, 0.6), 1.3)
    if climb > 0 and burn < 0.98:
        for k in range(2):
            def radius(s, k=k):
                return 1.9 - 1.0 * s + 0.25 * math.sin(9 * s + k)

            path = spiral_path(foot, radius, 13.0, 1.3, math.pi * k + 0.6, burn, max(climb, burn + 0.02))
            obj = mesh_object(f"strand{k}", ribbons(path, lambda s: 1.0 * math.sin(math.pi * s) ** 0.5 * (1 - 0.4 * burn), 2),
                              col, across_mat(f"strand{k}", 1.0, cool, tip_fade=0.15, foot_fade=0.12, hot=1.2))
    # embers rising after it
    rnd = random.Random(31)
    for n in range(26):
        start = rnd.uniform(0.04, 0.3)
        life = rnd.uniform(0.35, 0.6)
        a = rnd.uniform(0, 6.28)
        r0 = rnd.uniform(0.3, 1.8)
        h0 = rnd.uniform(0.5, 6.0)
        rise = rnd.uniform(6, 12)
        size = rnd.uniform(0.07, 0.13)
        tt = t - start
        if tt <= 0 or tt > life:
            continue
        p = foot + Vector((math.cos(a + 2.0 * tt) * (r0 + 0.8 * tt), math.sin(a + 2.0 * tt) * (r0 + 0.8 * tt), h0 + rise * tt))
        u = tt / life
        colour = mix(CORE, GOLD, min(u * 2, 1)) if u < 0.5 else mix(GOLD, ORANGE, (u - 0.5) * 2)
        obj = mesh_object(f"ember{n}", speck(size), col, flame_mat(f"ember{n}", colour, 2.4, 1.0 - ease_in(span(u, 0.6, 1))))
        obj.location = p
    # the shock ring
    u = span(t, 0.5 / 60, 0.3)
    if 0 < u < 1:
        r = 1.2 + 6.0 * ease_out(u, 3)
        band = 0.35 + 0.6 * u
        obj = mesh_object("ring", annulus(max(r - band, 0.1), r), col,
                          ring_mat("ring", GOLD, 2.0, 1.0 - ease_in(u, 1.4), 0.0, 0.7))
        obj.location = foot + Vector((0, 0, 0.03))
    # the puff where the pillar's top breaks
    tones = SMOKE_NIGHT if night else SMOKE_DAY
    for n in range(4):
        start = 0.2 + 0.03 * n
        u = span(t, start, start + 0.5)
        if u <= 0 or u >= 1:
            continue
        rnd2 = random.Random(70 + n)
        off = Vector((rnd2.uniform(-1.4, 1.4), rnd2.uniform(-1.4, 1.4), rnd2.uniform(-0.6, 0.6)))
        r = (0.9 + 0.4 * rnd2.random()) * (0.6 + 0.8 * ease_out(u, 2))
        op = 0.8 * (1.0 - ease_in(u, 1.5)) * ease_out(span(t, start, start + 0.05))
        obj = mesh_object(f"puff{n}", lumpy_sphere(1.0, 80 + n, lumps=0.25, subdiv=2), col, smoke_mat(f"puff{n}", tones, op))
        obj.location = foot + Vector((0, 0, 10.5 + 1.5 * ease_out(u))) + off
        obj.scale = (r, r, r * 0.85)
    lights.append((foot + up * 3.0, ORANGE, 850 * (snap - 0.95 * ease_in(span(t, 0.12, 0.6), 1.1))))


# the burn's tongues: where they stand on the foe (Roblox, in the torso's own space: X its right, Y up, Z its back), and
# how they lean (its own space), their length, width and beat. Shoulders and back only: nothing out of the head or neck.
TONGUES = [  # the arms' tops are 1.75 out from the torso's middle and 0.9 up; its back 0.75 behind; the head is 2.7 wide
    ((-1.7, 1.0, 0.1), (-0.35, 1.0, 0.25), 3.2, 1.6, 0.47, 0.0),    # the far shoulder
    ((1.7, 1.0, 0.15), (0.35, 1.0, 0.25), 3.0, 1.55, 0.53, 0.6),    # the near shoulder
    ((-1.9, -0.3, 0.4), (-0.3, 1.0, 0.3), 2.5, 1.3, 0.39, 0.3),     # the far arm, its back
    ((1.9, -0.4, 0.4), (0.3, 1.0, 0.3), 2.4, 1.25, 0.36, 0.45),     # the near arm, its back
    ((-0.6, 0.3, 0.85), (-0.05, 1.0, 0.45), 3.1, 1.5, 0.43, 0.8),   # the back, rising behind the torso
    ((0.6, -0.5, 0.85), (0.05, 1.0, 0.45), 2.6, 1.35, 0.58, 0.15),  # the back, lower
    ((0.0, -1.3, 0.7), (0.0, 1.0, 0.5), 2.2, 1.2, 0.41, 0.55),      # the hips, behind
    ((1.2, -1.6, 0.2), (0.25, 1.0, 0.2), 1.8, 1.0, 0.33, 0.9),      # the near hip
]


def torso_space(pose):
    """The torso's frame in Roblox: origin, right, up, back."""
    return pose.torso, pose.right, pose.up, -pose.look


def burn_tongues(t, pose, col, night, lights, sizes=TONGUES):
    o, right, upv, back = torso_space(pose)
    for n, (at, lean, length, width, beat, phase) in enumerate(sizes):
        foot = o + right * at[0] + upv * at[1] + back * at[2]
        d = (right * lean[0] + upv * lean[1] + back * lean[2]).normalized()
        cyc = ((t / beat) + phase) % 1.0
        # a lick: it stretches up, then shrinks back and thins; a sway across
        size = 0.86 + 0.16 * math.sin(2 * math.pi * cyc) + 0.07 * math.sin(4 * math.pi * cyc + 1.0)
        sway = 0.35 * math.sin(2 * math.pi * cyc + 0.7)
        side = d.cross(upv)
        if side.length < 1e-3:
            side = right
        side.normalize()
        bend = (back * 0.22 + side * sway * 0.6) * length * size
        path = [to_bl(p) for p in curve(foot, d, length * size, bend)]
        lick(f"tongue{n}", path, width * (0.85 + 0.25 * size), 0.97, col, 0.0, hot=1.0, foot=0.7)
    burn_embers(t, pose, col)
    lights.append((to_bl(o + upv * 1.6 + back * 0.6 + right * 1.2), ORANGE, 260 * (1 + 0.15 * math.sin(t * 17))))


def burn_embers(t, pose, col, n_embers=14):
    o, right, upv, back = torso_space(pose)
    rnd = random.Random(5)
    for n in range(n_embers):
        life = rnd.uniform(0.5, 0.8)
        phase = rnd.uniform(0, life)
        a = rnd.uniform(0, 6.28)
        r0 = rnd.uniform(0.6, 1.3)
        h0 = rnd.uniform(1.0, 2.0)
        rise = rnd.uniform(3.5, 6.0)
        size = rnd.uniform(0.06, 0.11)
        tt = (t + phase) % life
        start = o + upv * h0 + right * (math.cos(a) * r0) + back * (math.sin(a) * r0 * 0.6 + 0.3)
        p = start + upv * (rise * tt) + back * (0.8 * tt) + right * (0.4 * math.sin(6 * tt + n) * tt)
        u = tt / life
        colour = mix(CORE, GOLD, min(u * 2.5, 1)) if u < 0.4 else mix(GOLD, ORANGE, (u - 0.4) / 0.6)
        op = (1.0 - ease_in(span(u, 0.55, 1), 1.0)) * ease_out(span(u, 0, 0.08))
        obj = mesh_object(f"ember{n}", speck(size), col, flame_mat(f"ember{n}", colour, 2.4, op))
        obj.location = to_bl(p)


def burn_wrap(t, pose, col, night, lights):
    """The wrap: two strands of flame wound round the body outside the arms, from the hips to the shoulders, turning so
    they seem to climb, licks flickering up off them, embers. No tongues on the shoulders: with the strands' arcs they
    read as a face from behind."""
    o, right, upv, back = torso_space(pose)
    spin = 2 * math.pi * (t / 0.56)
    up = Vector((0, 0, 1))
    # the two strands differ in height, climb and phase, so no view lines them up into a pattern or a face
    for k, (low, height, turns, phase) in enumerate(((2.0, 3.8, 1.15, 0.0), (0.4, 2.4, 0.6, 2.3))):
        foot = to_bl(o - upv * low)

        def radius(s, k=k):
            return 2.3 - 0.3 * s + 0.12 * math.sin(7 * s + k * 2)

        path = spiral_path(foot, radius, height, turns, phase + spin * (1.0 + 0.3 * k), 0.0, 1.0, rows=40)
        mesh_object(f"wrap{k}", ribbons(path, lambda s: 1.1 * min(s / 0.15, 1.0) ** 0.6 * (1 - s) ** 0.5, 3), col,
                    across_mat(f"wrap{k}", 0.97, 0.15, tip_fade=0.2, foot_fade=0.1))
        # licks rising off the strand, flickering, so the coil reads as burning (irregular spacing, no wheel)
        for j, at in enumerate((0.12, 0.27, 0.36, 0.55, 0.68, 0.83)):
            i = int(at * 40)
            beat = 0.3 + 0.07 * ((j * 5 + k * 3) % 4)
            cyc = (t / beat + 0.37 * j + 0.5 * k) % 1.0
            size = 0.75 + 0.3 * math.sin(2 * math.pi * cyc)
            base = path[i]
            outward = Vector((base.x - foot.x, base.y - foot.y, 0)).normalized()
            d = (up + outward * 0.35).normalized()
            lick(f"wl{k}_{j}", curve(base, d, (1.0 + 0.5 * (j % 2)) * size, outward * 0.25 * size, n=10),
                 0.75 * (0.8 + 0.2 * size), 0.95, col, 0.1, foot=0.8)
    burn_embers(t, pose, col)
    lights.append((to_bl(o + upv * 0.6 + right * 1.2), ORANGE, 240 * (1 + 0.15 * math.sin(t * 17))))


LOOKS = {"fall_a": fall_a, "fall_b": fall_b, "burn_a": burn_tongues, "burn_b": burn_wrap}


# --- the run ----------------------------------------------------------------------------------------------------------

def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    # paths against the project, never Blender's own working folder (a relative path lands on the drive's root)
    root = Path(__file__).resolve().parents[2]
    pose_path, out, look = root / argv[0], root / argv[1], argv[2]
    times = [float(x) for x in argv[3].split(",")]
    heading = float(argv[4]) if len(argv) > 4 else None
    out.mkdir(parents=True, exist_ok=True)
    raw = json.loads(Path(pose_path).read_text())
    pose = Pose(raw)
    scene = reset()
    width, height = 2483, 1134
    cam = camera_from(raw, scene, width, height)
    hold = collection("Hold")
    stage_col = collection("Stage")
    fx = collection("Fx")
    lit = collection("Lit")
    white = white_mat()
    is_burn = look.startswith("burn")
    bodies = ["Lead_573369515", "Avatar"] + (["brawler_75"] if is_burn else [])
    if heading is not None:
        bodies = ["brawler_75"]
    for name in bodies:
        for p in raw["Bodies"][name]:
            m = cframe(p["C"])
            box(f"hold_{p['N']}", p["S"], m, hold, white)
    floor_m = Matrix.Translation(rb(pose.torso.x, FLOOR_Y - 0.5, pose.torso.z))
    box("floor", (400, 1.0, 400), C @ Matrix.Translation(Vector((pose.torso.x, FLOOR_Y - 0.5, pose.torso.z))), hold, white)
    _ = floor_m
    if heading is not None:
        # a plain stage: the foe in dark grey, the camera at the game's distance and pitch, `heading` degrees round
        for o in list(hold.objects):
            if o.name != "floor":
                o.data.materials.clear()
                o.data.materials.append(grey_mat())
        game = cam.matrix_world.copy()
        centre = to_bl(pose.torso)
        rel = game.translation - centre
        turn = Matrix.Rotation(math.radians(heading), 4, "Z")
        cam.matrix_world = Matrix.Translation(centre) @ turn @ Matrix.Translation(rel) @ game.to_3x3().to_4x4()
        aim = centre + Vector((0, 0, 1.0))
        direction = aim - cam.matrix_world.translation
        cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
        cam.data.angle_y = math.radians(40)
        scene.render.resolution_x, scene.render.resolution_y = 600, 600
    globals()["EYE"] = cam.matrix_world.translation.copy()
    view = scene.view_layers[0]
    night = "night" in out.name
    for t in times:
        for o in list(fx.objects) + list(lit.objects):
            bpy.data.objects.remove(o, do_unlink=True)
        lights = []
        LOOKS[look](t, pose, fx, night, lights)
        tag = f"{t:.3f}"
        # the effect, the bodies and floor held out (on the plain stage the foe is drawn, the floor held out)
        view.layer_collection.children["Hold"].holdout = heading is None
        view.layer_collection.children["Hold"].exclude = False
        if heading is not None:
            bpy.data.objects["floor"].hide_render = True
        view.layer_collection.children["Fx"].exclude = False
        view.layer_collection.children["Lit"].exclude = True
        scene.render.filepath = str(out / f"fx_{tag}.exr")
        bpy.ops.render.render(write_still=True)
        if heading is not None:
            continue
        # the light it throws, on white bodies and floor
        for (p, colour, power) in lights:
            if power <= 1:
                continue
            ld = bpy.data.lights.new("fire", "POINT")
            ld.color = colour
            ld.energy = power * SCALE
            ld.shadow_soft_size = 0.8
            ld.use_custom_distance = True
            ld.cutoff_distance = 40
            lo = bpy.data.objects.new("fire", ld)
            lit.objects.link(lo)
            lo.location = p
        view.layer_collection.children["Hold"].holdout = False
        view.layer_collection.children["Fx"].exclude = True
        view.layer_collection.children["Lit"].exclude = False
        scene.render.filepath = str(out / f"light_{tag}.exr")
        bpy.ops.render.render(write_still=True)
        view.layer_collection.children["Fx"].exclude = False
    print("done", look, len(times))


if __name__ == "__main__":
    main()
