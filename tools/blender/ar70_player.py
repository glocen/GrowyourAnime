"""AR70, the icon as a render of a Roblox player: our own blocky player breaking a Void Shard, and a Voidkin rising out of
its light (research's order of 2026-11-27, 18:30; the study, docs/research/game-icons.md). For
tools/ui/ar70_player_targets.py, which grades it and sets the logotype.

    blender.exe -b --factory-startup --python tools/blender/ar70_player.py -- <out_dir> <shot> [samples] [size]

The study's DESIGN, as made here:
- a lit place, not the void's dark: an evening sky with cloud banks, blue above and warm at the horizon, over a paved
  ground, with the player's red apart from the sky;
- the player: a generic R6-shaped block player of our own (no real avatar, no catalog item), a hoodie, jeans and
  sneakers, swept hair of our own and a drawn face in three marks. The read is the pose;
- the big thing: the shard's light, and a Voidkin rising out of it as a figure of that light, two to three times the
  player and the brightest thing in the frame. The figure is Lyric's (build/handoff/Lyric), read by its outline: her
  bob, her mic-staff, her two speakers; her paint isn't shown;
- the light: the shard's burst as the key on the player, the low sun behind as a warm rim, a cool fill;
- a low, wide camera, the shard near the lens, the background soft.

Shots: A, the raise; B, the offer; C, the smash (SHOTS). A and B are in gold light on a blue sky; C is in Lyric's own
Rare blue against a warm evening, the colour option.

Each shot writes <out>/<shot>.npy (the render in linear light, float32, rows top down), <out>/<shot>_light.npy (the
Voidkin and the burst alone, for the grade's glow) and <out>/<shot>.json (where the face, the shard and the Voidkin's
head fall). Cycles on the CPU, under build/locks/blender.lock.
"""
import json
import math
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Euler, Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import reveal_blockin as rb  # noqa: E402  (the Void Shard's form: its outline, five pieces, four seams)
import mesh_sheet as ms  # noqa: E402  (a fighter's handoff meshes, read back)
import rook_model as rm  # noqa: E402  (the Blender lock)


def srgb(code, a=1.0):
    def lin(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return tuple(lin(int(code[i:i + 2], 16) / 255) for i in (1, 3, 5)) + (a,)


# --- the player's look: ours, generic -------------------------------------------------------------------------------
LOOK = dict(skin="#F1C29A", hoodie="#E8462E", tee="#F6F1E6", jeans="#2D3D66", shoe="#F4F4F2", sole="#3A3F4A",
            hair="#2A1C18", eye="#141726", mouth="#3B1418")
SHARD = dict(lit="#9886EC", mid="#5B49B2", dark="#33276F", edge="#F5F0FF")
GOLD, GOLD_HOT = "#FFC75A", "#FFF4D6"


# --- materials -------------------------------------------------------------------------------------------------------

def cloth(name, colour, rough=0.78, sheen=0.25):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    p = m.node_tree.nodes["Principled BSDF"]
    p.inputs["Base Color"].default_value = srgb(colour)
    p.inputs["Roughness"].default_value = rough
    if "Sheen Weight" in p.inputs:
        p.inputs["Sheen Weight"].default_value = sheen
    return m


def glow(name, colour, strength):
    """Light: an emission of `colour` at `strength`."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nodes, links = m.node_tree.nodes, m.node_tree.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    em = nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = srgb(colour)
    em.inputs["Strength"].default_value = strength
    links.new(em.outputs[0], out.inputs["Surface"])
    return m


def spirit(name, colour, strength, fade, hot_colour=GOLD_HOT):
    """A figure of light: `colour` where it faces us, white-hot toward its outline, nearly opaque so its outline reads
    at 150 px; clear below fade[0] up the figure (from the root its Texture Coordinate is pointed at), whole above
    fade[1], so it rises out of the light."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nodes, links = m.node_tree.nodes, m.node_tree.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    em = nodes.new("ShaderNodeEmission")
    clear = nodes.new("ShaderNodeBsdfTransparent")
    lw = nodes.new("ShaderNodeLayerWeight")
    lw.inputs["Blend"].default_value = 0.55
    edge = nodes.new("ShaderNodeMapRange")
    edge.inputs["From Min"].default_value, edge.inputs["From Max"].default_value = 0.05, 0.75
    edge.inputs["To Min"].default_value = 0.98
    links.new(lw.outputs["Facing"], edge.inputs["Value"])
    hot = nodes.new("ShaderNodeMix")   # the colour: white-hot facing us, deep gold toward the outline
    hot.data_type = "RGBA"
    hot.inputs["A"].default_value = srgb(colour)
    hot.inputs["B"].default_value = srgb(hot_colour)
    curve = nodes.new("ShaderNodeMath")
    curve.operation = "POWER"
    curve.inputs[1].default_value = 2.0
    links.new(lw.outputs["Facing"], curve.inputs[0])
    links.new(curve.outputs[0], hot.inputs["Factor"])
    links.new(hot.outputs["Result"], em.inputs["Color"])
    k = nodes.new("ShaderNodeMath")
    k.operation = "MULTIPLY_ADD"
    links.new(curve.outputs[0], k.inputs[0])
    k.inputs[1].default_value = strength * 2.2
    k.inputs[2].default_value = strength
    links.new(k.outputs[0], em.inputs["Strength"])
    tc = nodes.new("ShaderNodeTexCoord")
    sep = nodes.new("ShaderNodeSeparateXYZ")
    rise = nodes.new("ShaderNodeMapRange")
    rise.inputs["From Min"].default_value, rise.inputs["From Max"].default_value = fade
    links.new(tc.outputs["Object"], sep.inputs[0])
    links.new(sep.outputs["Z"], rise.inputs["Value"])
    both = nodes.new("ShaderNodeMath")
    both.operation = "MULTIPLY"
    links.new(edge.outputs["Result"], both.inputs[0])
    links.new(rise.outputs["Result"], both.inputs[1])
    mix = nodes.new("ShaderNodeMixShader")
    links.new(both.outputs[0], mix.inputs["Fac"])
    links.new(clear.outputs[0], mix.inputs[1])
    links.new(em.outputs[0], mix.inputs[2])
    links.new(mix.outputs[0], out.inputs["Surface"])
    return m


def crystal(name, colour, glow_colour, glow_k):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    p = m.node_tree.nodes["Principled BSDF"]
    p.inputs["Base Color"].default_value = srgb(colour)
    p.inputs["Roughness"].default_value = 0.12
    p.inputs["Emission Color"].default_value = srgb(glow_colour)
    p.inputs["Emission Strength"].default_value = glow_k
    return m


def face_image(path):
    """The player's face, ours, in three marks: eyes with a glint under brows driven down, and a wide set grin.
    Drawn on the face patch's own unwrap (u across 110 degrees of the head, v up its height), alpha outside the marks."""
    n = 512
    v, u = np.mgrid[0:n, 0:n] / (n - 1)
    v = 1.0 - v
    rgba = np.zeros((n, n, 4), np.float32)

    def put(mask, colour):
        c = np.array(srgb(colour)[:3])
        rgba[mask, :3] = c
        rgba[mask, 3] = 1.0

    for e in (-1, 1):
        cx, cy = 0.5 + e * 0.155, 0.53
        eye = ((u - cx) / 0.062) ** 2 + ((v - cy) / 0.105) ** 2 < 1.0
        put(eye, LOOK["eye"])
        glint = ((u - cx + e * 0.018) / 0.022) ** 2 + ((v - cy - 0.04) / 0.03) ** 2 < 1.0
        put(glint, "#FFFFFF")
        # the brow: a thick bar falling toward the middle
        t = (u - cx) * e
        line = 0.70 - 0.32 * (0.09 - t)
        brow = (np.abs(t) < 0.095) & (np.abs(v - line) < 0.026)
        put(brow, LOOK["eye"])
    # the grin: a wide arc, the teeth across its top
    dx, dy = (u - 0.5) / 0.2, (v - 0.33) / 0.11
    grin = (dx ** 2 + dy ** 2 < 1.0) & (v < 0.35)
    put(grin, LOOK["mouth"])
    teeth = grin & (v > 0.285)
    put(teeth, "#FFFFFF")
    img = bpy.data.images.new("Face", n, n, alpha=True)
    img.pixels.foreach_set(np.flipud(rgba).ravel())
    img.filepath_raw = str(path)
    img.file_format = "PNG"
    img.save()
    return img


def decal(name, image):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nodes, links = m.node_tree.nodes, m.node_tree.links
    p = nodes["Principled BSDF"]
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = image
    tex.interpolation = "Cubic"
    links.new(tex.outputs["Color"], p.inputs["Base Color"])
    links.new(tex.outputs["Alpha"], p.inputs["Alpha"])
    p.inputs["Roughness"].default_value = 0.45
    m.blend_method = "HASHED" if hasattr(m, "blend_method") else None
    return m


# --- shapes ----------------------------------------------------------------------------------------------------------

def block(name, size, at, material, bevel=0.08, parent=None):
    """A box of `size`, its centre at `at` in its parent's space, its edges rounded by `bevel`."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=Vector(size), verts=bm.verts)
    bmesh.ops.translate(bm, vec=Vector(at), verts=bm.verts)
    obj = bl.object_from_bmesh(name, bm, material)
    if bevel:
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width, mod.segments = bevel, 3
        obj.modifiers.new("Smooth", "WEIGHTED_NORMAL")
    if parent:
        obj.parent = parent
    return obj


def pivot(name, at, parent=None, rot=(0, 0, 0)):
    e = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(e)
    e.location = at
    e.rotation_euler = Euler([math.radians(a) for a in rot], "XYZ")
    if parent:
        e.parent = parent
    return e


def rounded_cylinder(name, r, h, round_r, material, parent=None, at=(0, 0, 0)):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=48, radius1=r, radius2=r, depth=h)
    bmesh.ops.translate(bm, vec=Vector(at) + Vector((0, 0, h / 2)), verts=bm.verts)
    obj = bl.object_from_bmesh(name, bm, material)
    mod = obj.modifiers.new("Bevel", "BEVEL")
    mod.width, mod.segments, mod.limit_method = round_r, 6, "ANGLE"
    for poly in obj.data.polygons:
        poly.use_smooth = True
    if parent:
        obj.parent = parent
    return obj


def face_patch(name, r, z0, z1, arc, material, parent):
    """A strip of the head's side, `arc` degrees round its front (-Y), from z0 to z1, unwrapped flat for the face."""
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UV")
    cols, rows = 24, 8
    verts = [[bm.verts.new((r * math.sin(math.radians(-arc / 2 + arc * i / cols)),
                            -r * math.cos(math.radians(-arc / 2 + arc * i / cols)), z0 + (z1 - z0) * j / rows))
              for j in range(rows + 1)] for i in range(cols + 1)]
    for i in range(cols):
        for j in range(rows):
            f = bm.faces.new((verts[i][j], verts[i + 1][j], verts[i + 1][j + 1], verts[i][j + 1]))
            for loop, (a, b) in zip(f.loops, ((i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1))):
                loop[uv].uv = (a / cols, b / rows)
    obj = bl.object_from_bmesh(name, bm, material)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    obj.parent = parent
    return obj


HAIR = (  # (root, direction, length, width) in the head's space: crown blades up and back, then the fringe, then the sides
    ((-0.42, 0.10, 1.38), (-0.55, 0.55, 0.65), 0.95, 0.5), ((-0.05, 0.05, 1.45), (-0.1, 0.6, 0.8), 1.05, 0.55),
    ((0.35, 0.10, 1.40), (0.5, 0.6, 0.65), 0.95, 0.5), ((0.0, 0.45, 1.3), (0.0, 0.9, 0.4), 0.85, 0.6),
    ((-0.5, 0.4, 1.2), (-0.6, 0.8, 0.1), 0.7, 0.45), ((0.5, 0.4, 1.2), (0.6, 0.8, 0.1), 0.7, 0.45),
    ((-0.38, -0.52, 1.36), (0.25, -0.35, -0.9), 0.62, 0.48), ((-0.02, -0.56, 1.38), (0.45, -0.3, -0.85), 0.6, 0.48),
    ((0.34, -0.52, 1.34), (0.75, -0.25, -0.6), 0.55, 0.42),
    ((-0.62, -0.2, 1.15), (-0.15, -0.1, -1.0), 0.5, 0.36), ((0.62, -0.2, 1.15), (0.2, -0.1, -1.0), 0.45, 0.34),
)


def blade(name, root, direction, length, width, thick, material, parent):
    """A lock of hair: flat, wide at its root, tapering to a point along `direction`, its flat facing out from the head."""
    d = Vector(direction).normalized()
    out = Vector(root).normalized()
    side = d.cross(out).normalized() if d.cross(out).length > 1e-3 else Vector((1, 0, 0))
    flat = side.cross(d).normalized()
    r = Vector(root)
    pts = []
    for k, w in ((0.0, 1.0), (0.45, 0.8)):
        c = r + d * length * k
        for a in (-1, 1):
            for b in (-1, 1):
                pts.append(c + side * a * width / 2 * w + flat * b * thick / 2 * (1 - k))
    pts.append(r + d * length + flat * 0.02)
    bm = rb.hull(pts)
    obj = bl.object_from_bmesh(name, bm, material)
    mod = obj.modifiers.new("Bevel", "BEVEL")
    mod.width, mod.segments = 0.05, 2
    obj.parent = parent
    return obj


def cone(name, r, length, at, direction, material, parent=None, sides=5):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=sides, radius1=r, radius2=0.0, depth=length)
    obj = bl.object_from_bmesh(name, bm, material)
    d = Vector(direction).normalized()
    obj.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    obj.location = Vector(at) + d * length / 2
    if parent:
        obj.parent = parent
    return obj


# --- the player ------------------------------------------------------------------------------------------------------

def player(mats, pose, root_at, turn, scale=1.0):
    """Our block player, posed: `pose` holds each joint's (x, y, z) degrees: hips, waist, neck, the shoulders and the
    hips' legs. R6's sizes: the torso 2 x 1 x 2, a limb 1 x 1 x 2, the head a rounded drum. Faces -Y at turn 0.
    Returns the head's pivot and both hands' pivots, for the shot's aim."""
    root = pivot("Root", root_at, rot=(0, 0, turn))
    root.scale = (scale,) * 3
    hips = pivot("Hips", (0, 0, 2.0), root, pose.get("hips", (0, 0, 0)))
    torso = pivot("Torso", (0, 0, 0), hips, pose.get("waist", (0, 0, 0)))
    block("Hoodie", (2.0, 1.0, 2.0), (0, 0, 1.0), mats["hoodie"], 0.1, torso)
    block("Tee", (0.62, 0.06, 1.5), (0, -0.5, 1.0), mats["tee"], 0.02, torso)
    block("Hood", (1.5, 0.5, 0.42), (0, 0.32, 2.02), mats["hoodie"], 0.16, torso)
    for e in (-1, 1):
        block("Cord", (0.06, 0.05, 0.6), (e * 0.22, -0.53, 1.45), mats["tee"], 0.01, torso)
        block("Pocket", (0.8, 0.05, 0.5), (e * 0.55, -0.52, 0.42), mats["hoodie_dark"], 0.04, torso)
    neck = pivot("Neck", (0, 0, 2.0), torso, pose.get("neck", (0, 0, 0)))
    rounded_cylinder("Head", 0.62, 1.22, 0.3, mats["skin"], neck, (0, 0, 0.02))
    face_patch("Face", 0.632, 0.14, 1.1, 116, mats["face"], neck)
    # hair, ours: a cap over the crown, blades swept up and back from it, a fringe falling to one side over the brow
    block("HairCap", (1.4, 1.4, 0.5), (0, 0.06, 1.22), mats["hair"], 0.24, neck)
    block("HairBack", (1.38, 0.55, 0.95), (0, 0.42, 0.86), mats["hair"], 0.22, neck)
    for i, (at_, d, ln, w) in enumerate(HAIR):
        blade(f"Lock{i}", at_, d, ln, w, 0.2, mats["hair"], neck)
    hands = {}
    for side, e in (("R", -1), ("L", 1)):
        sh = pivot(f"Shoulder{side}", (e * 1.5, 0, 1.5), torso, pose.get(f"arm{side}", (0, 0, 0)))
        block(f"Sleeve{side}", (1.0, 1.0, 1.55), (0, 0, -0.32), mats["hoodie"], 0.1, sh)
        block(f"Cuff{side}", (1.02, 1.02, 0.16), (0, 0, -1.05), mats["hoodie_dark"], 0.05, sh)
        block(f"Hand{side}", (0.86, 0.86, 0.5), (0, 0, -1.33), mats["skin"], 0.14, sh)
        hands[side] = pivot(f"Grip{side}", (0, 0, -1.45), sh)
        hip = pivot(f"Hip{side}", (e * 0.5, 0, 0.0), hips, pose.get(f"leg{side}", (0, 0, 0)))
        block(f"Jeans{side}", (0.98, 0.98, 1.62), (0, 0, -0.81), mats["jeans"], 0.08, hip)
        block(f"Shoe{side}", (1.0, 1.16, 0.4), (0, -0.08, -1.8), mats["shoe"], 0.12, hip)
        block(f"Sole{side}", (1.02, 1.18, 0.1), (0, -0.08, -1.98), mats["sole"], 0.03, hip)
    return neck, hands


# --- the shard and its light -------------------------------------------------------------------------------------------

def shard(mats, at, scale, turn, part, rng):
    """The Void Shard (reveal_blockin's form) breaking: its five pieces pushed out from its middle by `part` studs,
    with a gold-white core where they part."""
    parent = pivot("Shard", at, rot=turn)
    parent.scale = (scale,) * 3
    for name, sides in rb.PIECES:
        bm = rb.hull(rb.piece_points(sides))
        c = sum((v.co for v in bm.verts), Vector()) / len(bm.verts)
        obj = bl.object_from_bmesh(f"Piece{name}", bm, mats["shard"])
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width, mod.segments = 0.04, 2
        obj.parent = parent
        out = Vector((c.x, c.y * 0.4, c.z)).normalized() if c.length > 1e-3 else Vector((0, 0, 1))
        obj.location = out * part
        obj.rotation_euler = Euler([math.radians(a) for a in rng.uniform(-14, 14, 3)], "XYZ")
    core = bl.object_from_bmesh("Core", rb.hull(rb.body_points(0.55)), mats["core"])
    core.parent = parent
    return parent


def burst(mats, at, reach, count, rng, up=(0, 0, 1), spread=1.0, thin=1.0):
    """Rays of the shard's light: thin long cones from its middle, most of them up."""
    up = Vector(up).normalized()
    for i in range(count):
        d = Vector(rng.normal(0, 1, 3))
        d = (d.normalized() * spread + up * 1.2).normalized()
        cone(f"Ray{i}", rng.uniform(0.05, 0.16) * thin, reach * rng.uniform(0.45, 1.0), at, d, mats["ray"], sides=4)


def chips(mats, at, count, reach, rng, face=None):
    """Splinters of the shard and sparks thrown up from it; none lands on the face (within 1.4 studs of `face`)."""
    def clear(where):
        return face is None or (where - Vector(face)).length > 1.4
    for i in range(count):
        d = Vector(rng.normal(0, 1, 3)).normalized()
        d.z = abs(d.z) * 0.8 + 0.2
        s = rng.uniform(0.08, 0.28)
        bm = rb.hull(rb.body_points(s))
        where = Vector(at) + d * rng.uniform(0.6, reach)
        if not clear(where):
            bm.free()
            continue
        obj = bl.object_from_bmesh(f"Chip{i}", bm, mats["shard"])
        obj.location = where
        obj.rotation_euler = Euler(rng.uniform(0, 6.28, 3), "XYZ")
    for i in range(count):
        d = Vector(rng.normal(0, 1, 3)).normalized()
        d.z = abs(d.z) + 0.3
        r, where = rng.uniform(0.02, 0.04), Vector(at) + d * rng.uniform(0.5, reach)
        if clear(where):
            bl.sphere(f"Spark{i}", r, 8, 4, mats["spark"]).location = where


# --- the Voidkin of light ----------------------------------------------------------------------------------------------

HANDOFF = Path(__file__).resolve().parents[2] / "build" / "handoff"
JOINTS = {"Right Arm": (1.0, 0.0, 3.5), "Left Arm": (-1.0, 0.0, 3.5), "Right Leg": (0.5, 0.0, 2.0),
          "Left Leg": (-0.5, 0.0, 2.0)}  # R6's joints in the handoff's frame read into Blender's (x, -z, y)


def fighter_light(mats, fighter, at, scale, turn, pose):
    """One of our Voidkin as a figure of light: its handoff meshes (build/handoff/<fighter>), each on its rig part,
    the limbs turned about R6's joints by `pose` (degrees, in the fighter's own frame: it faces +Y as read), all in
    the Voidkin's light. The figure reads by its outline, so its paint isn't shown. Returns its root and a pivot 0.6
    under its head's middle."""
    recipe = json.loads((HANDOFF / fighter / f"{fighter}.recipe.json").read_text(encoding="utf-8"))
    edges = set(recipe.get("edges", {}).get("pieces", []))
    root = pivot("Kin", at, rot=(0, 0, turn))
    root.scale = (scale,) * 3
    body = pivot("KinBody", (0, 0, 0), root, (0, 0, 180))   # the handoff faces +Y as read; ours face -Y
    limbs = {}
    for part, joint in JOINTS.items():
        j = pivot(f"Kin{part}", joint, body, pose.get(part, (0, 0, 0)))
        limbs[part] = (j, Vector(joint))
    for piece in recipe["pieces"]:
        if piece["name"] in edges:
            continue
        mesh, _ = ms.load(HANDOFF / fighter / piece["mesh"])
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        bm.to_mesh(mesh)
        bm.free()
        obj = bpy.data.objects.new(piece["name"], mesh)
        bpy.context.scene.collection.objects.link(obj)
        obj.data.materials.append(mats["kin"])
        x, y, z = piece["centre"]
        place = Vector((x, -z, y))   # each mesh is about its own centre; the recipe says where that is on the body
        if piece["on"] in limbs:
            j, joint = limbs[piece["on"]]
            obj.parent = j
            obj.location = place - joint
        else:
            obj.parent = body
            obj.location = place
    head = next(p for p in recipe["pieces"] if p["on"] == "Head")["centre"]
    neck = pivot("KinNeck", (0, 0, head[1] - 0.6), body)
    return root, neck


def impact(mats, at, rng, count=11, reach=6.0):
    """The smash on the ground: cracks of the shard's light running out from under it, each a few bent strokes, and a
    low ring of light spreading."""
    o = Vector((at[0], at[1], 0.02))
    for i in range(count):
        a = 2 * math.pi * i / count + rng.uniform(-0.25, 0.25)
        p0, ln = o.copy(), rng.uniform(0.45, 1.0) * reach
        for k in range(3):
            a += rng.uniform(-0.45, 0.45)
            step = ln / 3
            p1 = p0 + Vector((math.cos(a), math.sin(a), 0)) * step
            mid, d = (p0 + p1) / 2, p1 - p0
            w = 0.1 * (1 - k / 3) + 0.03
            crack = block(f"Crack{i}_{k}", (d.length + w, w, 0.03), (0, 0, 0), mats["ray"], 0.0)
            crack.location = mid
            crack.rotation_euler = (0, 0, math.atan2(d.y, d.x))
            p0 = p1
    bm = bmesh.new()
    bmesh.ops.create_circle(bm, cap_ends=False, segments=64, radius=reach * 0.55)
    ring = bl.object_from_bmesh("Ring", bm, mats["ray"])
    ring.location = o + Vector((0, 0, 0.05))
    mod = ring.modifiers.new("Skin", "SOLIDIFY")
    mod.thickness = 0.06
    wire = ring.modifiers.new("Wire", "WIREFRAME")
    wire.thickness = 0.08


# --- the place ---------------------------------------------------------------------------------------------------------

def sky(scene, zenith, mid, horizon, sun_dir, strength=1.0):
    world = bpy.data.worlds.new("Dusk")
    scene.world = world
    world.use_nodes = True
    nodes, links = world.node_tree.nodes, world.node_tree.links
    bg = nodes["Background"]
    tc = nodes.new("ShaderNodeTexCoord")
    sep = nodes.new("ShaderNodeSeparateXYZ")
    ramp = nodes.new("ShaderNodeValToRGB")
    links.new(tc.outputs["Generated"], sep.inputs[0])
    links.new(sep.outputs["Z"], ramp.inputs["Fac"])
    cr = ramp.color_ramp
    cr.elements[0].position, cr.elements[0].color = 0.0, srgb(horizon)
    cr.elements[1].position, cr.elements[1].color = 0.55, srgb(zenith)
    e = cr.elements.new(0.14)
    e.color = srgb(mid)
    # the sun's glow on the sky, round its direction
    dot = nodes.new("ShaderNodeVectorMath")
    dot.operation = "DOT_PRODUCT"
    dot.inputs[1].default_value = Vector(sun_dir).normalized()
    links.new(tc.outputs["Generated"], dot.inputs[0])
    pw = nodes.new("ShaderNodeMath")
    pw.operation = "POWER"
    pw.inputs[1].default_value = 18.0
    clamp = nodes.new("ShaderNodeClamp")
    links.new(dot.outputs["Value"], clamp.inputs["Value"])
    links.new(clamp.outputs[0], pw.inputs[0])
    add = nodes.new("ShaderNodeMix")
    add.data_type, add.blend_type = "RGBA", "ADD"
    links.new(pw.outputs[0], add.inputs["Factor"])
    links.new(ramp.outputs["Color"], add.inputs["A"])
    add.inputs["B"].default_value = srgb("#FFB46A", 1.0)
    pw.inputs[1].default_value = 40.0
    # clouds: noise on the view's direction, flattened into banks, lit warm toward the sun and cool away from it
    flat = nodes.new("ShaderNodeVectorMath")
    flat.operation = "MULTIPLY"
    flat.inputs[1].default_value = (1.0, 1.0, 4.0)
    links.new(tc.outputs["Generated"], flat.inputs[0])
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 3.0
    noise.inputs["Detail"].default_value = 8.0
    noise.inputs["Roughness"].default_value = 0.58
    links.new(flat.outputs[0], noise.inputs["Vector"])
    puff = nodes.new("ShaderNodeMapRange")
    puff.inputs["From Min"].default_value, puff.inputs["From Max"].default_value = 0.47, 0.6
    links.new(noise.outputs["Fac"], puff.inputs["Value"])
    band = nodes.new("ShaderNodeMapRange")
    band.inputs["From Min"].default_value, band.inputs["From Max"].default_value = 0.8, 0.12
    links.new(sep.outputs["Z"], band.inputs["Value"])
    above = nodes.new("ShaderNodeMapRange")
    above.inputs["From Min"].default_value, above.inputs["From Max"].default_value = 0.0, 0.05
    links.new(sep.outputs["Z"], above.inputs["Value"])
    m1 = nodes.new("ShaderNodeMath")
    m1.operation = "MULTIPLY"
    links.new(puff.outputs["Result"], m1.inputs[0])
    links.new(band.outputs["Result"], m1.inputs[1])
    m2 = nodes.new("ShaderNodeMath")
    m2.operation = "MULTIPLY"
    links.new(m1.outputs[0], m2.inputs[0])
    links.new(above.outputs["Result"], m2.inputs[1])
    m2.use_clamp = True
    warm = nodes.new("ShaderNodeMath")
    warm.operation = "POWER"
    warm.inputs[1].default_value = 3.0
    links.new(clamp.outputs[0], warm.inputs[0])
    tint = nodes.new("ShaderNodeMix")
    tint.data_type = "RGBA"
    links.new(warm.outputs[0], tint.inputs["Factor"])
    tint.inputs["A"].default_value = srgb("#E9EEFA")
    tint.inputs["B"].default_value = srgb("#FFD3A4")
    clouds = nodes.new("ShaderNodeMix")
    clouds.data_type = "RGBA"
    links.new(m2.outputs[0], clouds.inputs["Factor"])
    links.new(add.outputs["Result"], clouds.inputs["A"])
    links.new(tint.outputs["Result"], clouds.inputs["B"])
    links.new(clouds.outputs["Result"], bg.inputs["Color"])
    bg.inputs["Strength"].default_value = strength


def ground(mats):
    plane = bl.box("Ground", (400, 400, 0.2), mats["paving"])
    plane.location = (0, 0, -0.1)
    return plane


def paving(name, colour):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nodes, links = m.node_tree.nodes, m.node_tree.links
    p = nodes["Principled BSDF"]
    brick = nodes.new("ShaderNodeTexBrick")
    brick.inputs["Scale"].default_value = 0.35
    brick.inputs["Color1"].default_value = srgb(colour)
    brick.inputs["Color2"].default_value = srgb("#6F6E7A")
    brick.inputs["Mortar"].default_value = srgb("#3E3C48")
    brick.inputs["Mortar Size"].default_value = 0.015
    tc = nodes.new("ShaderNodeTexCoord")
    links.new(tc.outputs["Object"], brick.inputs["Vector"])
    links.new(brick.outputs["Color"], p.inputs["Base Color"])
    p.inputs["Roughness"].default_value = 0.62
    return m


# --- the shots -------------------------------------------------------------------------------------------------------

LYRIC_POSE = {"Right Arm": (0, -38, 0), "Left Arm": (0, 150, 0), "Right Leg": (0, -8, 0), "Left Leg": (0, 8, 0)}

SHOTS = {
    # A, the raise: the player on the left turns to the shard he holds up on the right; the Voidkin rises out of its
    # light in the upper right, over his shoulder, in gold on a blue evening.
    "A": dict(
        player=dict(hips=(0, 0, 0), waist=(-8, 4, 0), neck=(-14, 0, 10), armR=(-30, -40, 0), armL=(-150, -20, -10),
                    legR=(-8, -10, 0), legL=(12, 10, 0)),
        root=(-1.6, 0, 0), turn=28, shard_hand="L", shard_off=(0.2, -0.3, 1.3), shard_scale=0.75, part=0.26,
        kin_screen=(0.66, 0.17), kin_far=21.0, kin_scale=3.4, kin_turn=-22, ray_up=(0.5, 0.4, 1.0),
        dolly=0.66, cam=(-1.0, -4.8, 2.4), aim=(1.3, 1.0, 7.0), lens=20, focus=(-1.2, 0.0, 4.6), fstop=6.0,
        sky=("#2E5BB8", "#7FB0F0", "#FFB37A"), sun=(-0.6, 0.8, 0.18),
    ),
    # B, the offer: he holds the cracking shard up at the lens, near and large, looking past it; the Voidkin rises out
    # of its light behind him on the left, in gold.
    "B": dict(
        player=dict(hips=(0, 0, 0), waist=(-6, 0, -8), neck=(-4, 0, 10), armR=(-92, 0, 12), armL=(-14, 0, -14),
                    legR=(-6, -12, 0), legL=(6, 12, 0)),
        root=(0.9, 0, 0), turn=-14, shard_hand="R", shard_off=(0.0, -0.15, 0.7), shard_scale=0.42, part=0.32,
        kin_screen=(0.3, 0.15), kin_far=25.0, kin_scale=3.4, kin_turn=16,
        ray_up=(-0.5, 0.3, 0.8), ray_reach=3.2, rays=12, ray_thin=0.45,
        dolly=0.66, cam=(-0.4, -4.8, 3.5), aim=(0.1, 0.0, 5.3), lens=21, focus=(0.6, -0.2, 4.6), fstop=4.0,
        sky=("#2A55B0", "#79AEEE", "#FFC184"), sun=(0.6, 0.8, 0.16),
    ),
    # C, the smash: he lunges and drives his fist down into the shard; it bursts and the ground cracks with its light;
    # the Voidkin rises out of it behind him on the left, in her own Rare blue, against a warm evening.
    "C": dict(
        light="rare", impact=True, core_k=12.0,
        player=dict(hips=(0, 0, 0), waist=(-28, 0, -10), neck=(14, 0, 14), armR=(-58, 0, 16), armL=(40, 0, -30),
                    legR=(-50, 0, 0), legL=(36, 0, 0)),
        root=(1.0, 0.4, -0.45), turn=-58, shard_hand="R", shard_off=(0.0, -0.45, -1.2), shard_scale=0.95, part=0.36,
        kin_screen=(0.33, 0.15), kin_far=25.0, kin_scale=3.4, kin_turn=14,
        ray_up=(-0.2, -0.3, 1.0), ray_reach=3.4, rays=9, ray_thin=0.5,
        dolly=0.62, cam=(-0.9, -4.4, 3.1), aim=(-0.4, 0.4, 2.15), lens=20, focus=(0.2, -0.4, 2.6), fstop=4.5,
        sky=("#3F6FC4", "#F6B48A", "#FF9A5A"), sun=(-0.7, 0.7, 0.2),
    ),
}


LIGHTS = {  # the shard's light, by shot: (the Voidkin's body, its white-hot, the rays, the key light on the player,
    # the body's strength: gold clips to lemon yellow above about 0.4, so it burns lower than the blue)
    "gold": ("#FF8A0A", GOLD_HOT, GOLD, "#FFE2A6", 0.4),
    "rare": ("#2E9BFF", "#E6F5FF", "#8CCBFF", "#CFE8FF", 0.85),   # Rare's own blue, Lyric's rarity (roster)
}


def materials(face_png, light="gold", core_k=24.0):
    body, hot, ray, _, body_k = LIGHTS[light]
    mats = {k: cloth(k, LOOK[k]) for k in ("hoodie", "tee", "jeans", "shoe", "sole")}
    mats["hoodie_dark"] = cloth("hoodie_dark", "#B8301F")
    mats["skin"] = cloth("skin", LOOK["skin"], rough=0.5, sheen=0.0)
    mats["hair"] = cloth("hair", LOOK["hair"], rough=0.45, sheen=0.4)
    mats["face"] = decal("face", face_image(face_png))
    mats["shard"] = crystal("shard", SHARD["mid"], SHARD["lit"], 0.6)
    mats["core"] = glow("core", hot, core_k)
    mats["ray"] = glow("ray", ray, 6.0)
    mats["spark"] = glow("spark", hot, 10.0)
    mats["kin"] = spirit("kin", body, body_k, fade=(0.3, 2.6), hot_colour=hot)
    mats["paving"] = paving("paving", "#8C8A96")
    return mats


def lights(scene, shot, shard_at):
    sun = bpy.data.lights.new("Sun", "SUN")
    sun.energy, sun.color, sun.angle = 5.0, srgb("#FFC38C")[:3], math.radians(3)
    s = bpy.data.objects.new("Sun", sun)
    scene.collection.objects.link(s)
    s.rotation_euler = (-Vector(shot["sun"])).to_track_quat("-Z", "Y").to_euler()
    key = bpy.data.lights.new("ShardLight", "POINT")
    key.energy, key.color, key.shadow_soft_size = 700, srgb(LIGHTS[shot.get("light", "gold")][3])[:3], 0.6
    k = bpy.data.objects.new("ShardLight", key)
    scene.collection.objects.link(k)
    k.location = shard_at
    fill = bpy.data.lights.new("Fill", "AREA")
    fill.energy, fill.color, fill.size = 900, srgb("#9CC4FF")[:3], 10
    f = bpy.data.objects.new("Fill", fill)
    scene.collection.objects.link(f)
    cam = Vector(shot["cam"])
    f.location = cam + Vector((-4, -2, 5))
    f.rotation_euler = (Vector(shot["aim"]) - f.location).to_track_quat("-Z", "Y").to_euler()


def camera(scene, shot, size):
    cam = bpy.data.cameras.new("Cam")
    cam.lens, cam.sensor_width = shot["lens"], 36
    cam.dof.use_dof = True
    cam.dof.aperture_fstop = shot["fstop"]
    obj = bpy.data.objects.new("Cam", cam)
    scene.collection.objects.link(obj)
    obj.location = shot["cam"]
    obj.rotation_euler = (Vector(shot["aim"]) - Vector(shot["cam"])).to_track_quat("-Z", "Y").to_euler()
    cam.dof.focus_distance = (Vector(shot["focus"]) - Vector(shot["cam"])).length
    scene.camera = obj
    scene.render.resolution_x = scene.render.resolution_y = size
    return obj


def where(scene, cam, point, size):
    from bpy_extras.object_utils import world_to_camera_view
    p = world_to_camera_view(scene, cam, Vector(point))
    return [round(p.x * size, 1), round((1 - p.y) * size, 1)]


def save_npy(exr, npy, size):
    img = bpy.data.images.load(str(exr))
    px = np.empty(size * size * 4, np.float32)
    img.pixels.foreach_get(px)
    np.save(npy, np.flipud(px.reshape(size, size, 4)))


def run(out, name, samples, size):
    shot = SHOTS[name]
    scene = bl.reset_scene()
    rng = np.random.default_rng(7)
    mats = materials(out / "face.png", shot.get("light", "gold"), shot.get("core_k", 24.0))
    neck, hands = player(mats, shot["player"], shot["root"], shot["turn"])
    bpy.context.view_layer.update()
    shot["shard_at"] = tuple(hands[shot["shard_hand"]].matrix_world.translation + Vector(shot["shard_off"]))
    shard(mats, shot["shard_at"], shot["shard_scale"], (0, 0, 20), shot["part"], rng)
    burst(mats, shot["shard_at"], shot.get("ray_reach", 5.0), shot.get("rays", 18), rng, up=shot.get("ray_up", (0, 0, 1)),
          spread=0.7, thin=shot.get("ray_thin", 1.0))
    chips(mats, shot["shard_at"], 14, 3.2, rng, face=neck.matrix_world @ Vector((0, 0, 0.7)))
    kin_root, kin_neck = fighter_light(mats, "Lyric", (0, 12, 6), shot["kin_scale"], shot["kin_turn"], LYRIC_POSE)
    for node in mats["kin"].node_tree.nodes:  # the rise is measured up the whole figure, from its own root
        if node.type == "TEX_COORD":
            node.object = kin_root
    if "dolly" in shot:  # move the lens along its line to the face, by `dolly` of the way: the face keeps its place in
        # the frame and grows (the study's head, 20 to 25% of the frame across)
        bpy.context.view_layer.update()
        face, was = neck.matrix_world @ Vector((0, 0, 0.7)), Vector(shot["cam"])
        now = face + (was - face) * shot["dolly"]
        for key in ("cam", "aim", "focus"):
            shot[key] = tuple(Vector(shot[key]) + now - was)
    cam = camera(scene, shot, size)
    # the Voidkin turned to the lens, upright in the frame, so its shape reads whole
    bpy.context.view_layer.update()
    r = cam.matrix_world.to_3x3()
    face = Matrix((r.col[0], -r.col[2], r.col[1])).transposed() @ Matrix.Rotation(math.radians(shot["kin_turn"]), 3, "Z")
    kin_root.rotation_euler = face.to_euler()
    # its head where the frame wants it (kin_screen, 0 to 1 from the top left), kin_far studs from the lens
    bpy.context.view_layer.update()
    sx, sy = shot["kin_screen"]
    tr, br, bl_, tl = cam.data.view_frame(scene=scene)
    ray = (cam.matrix_world.to_3x3() @ (tl + (tr - tl) * sx + (bl_ - tl) * sy)).normalized()
    want = cam.matrix_world.translation + ray * shot["kin_far"]
    head = kin_neck.matrix_world @ Vector((0, 0, 0.6))
    kin_root.location += want - head
    bpy.context.view_layer.update()
    if shot.get("impact"):
        impact(mats, shot["shard_at"], rng)
    ground(mats)
    sky(scene, *shot["sky"], shot["sun"])
    lights(scene, shot, shot["shard_at"])
    scene.render.engine = "CYCLES"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 6
    scene.cycles.transparent_max_bounces = 48
    scene.view_settings.view_transform = "Standard"
    scene.render.image_settings.file_format = "OPEN_EXR"
    scene.render.image_settings.color_depth = "32"
    for obj in scene.objects:
        if obj.type == "MESH" and obj.active_material and obj.active_material.name.startswith(
                ("core", "ray", "spark", "kin", "shard")):
            obj.visible_shadow = False
    bpy.context.view_layer.update()
    path = out / f"{name}.exr"
    scene.render.filepath = str(path)
    held = rm.lock(f"ar70_player.py {name}")
    try:
        bpy.ops.render.render(write_still=True)
        save_npy(path, out / f"{name}.npy", size)
        # the light alone, for the grade's glow: the Voidkin and the shard's burst on black, everything else held out
        for obj in scene.objects:
            mat = obj.active_material.name if obj.type == "MESH" and obj.active_material else ""
            if obj.type == "MESH" and not mat.startswith(("kin", "core", "ray", "spark")):
                obj.is_holdout = True
        scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.0
        scene.cycles.samples = max(8, samples // 4)
        light = out / f"{name}_light.exr"
        scene.render.filepath = str(light)
        bpy.ops.render.render(write_still=True)
        save_npy(light, out / f"{name}_light.npy", size)
    finally:
        held.unlink(missing_ok=True)
    centre = neck.matrix_world @ Vector((0, 0, 0.7))
    side = cam.matrix_world.to_3x3() @ Vector((0.7, 0, 0))   # the head with its hair is about 1.4 studs across
    head_w = abs(where(scene, cam, centre + side, size)[0] - where(scene, cam, centre - side, size)[0]) / size
    marks = dict(head=where(scene, cam, centre, size), head_w=round(head_w, 3),
                 shard=where(scene, cam, shot["shard_at"], size),
                 kin_head=where(scene, cam, kin_neck.matrix_world @ Vector((0, 0, 0.6)), size), size=size)
    (out / f"{name}.json").write_text(json.dumps(marks, indent=1), encoding="utf-8")
    print(f"{name}: {marks}")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    name = args[0]
    samples = int(args[1]) if len(args) > 1 else 96
    size = int(args[2]) if len(args) > 2 else 768
    run(out, name, samples, size)


if __name__ == "__main__":
    main()
