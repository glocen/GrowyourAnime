"""The Shade's model (AR2, delivery 2): one body and four masks on the R6 rig, one baked texture set for the five
types, the exports and the review sheet.

blender.exe -b --factory-startup --python tools/blender/shade_model.py -- <out_dir>

How it sits on R6: a rigid mesh for each of the five body parts, which carries the body's own surface, so the rig's
blocks are hidden; and four masks, each one piece on the Head, of which a Shade wears one. Everything shares one
1024 px atlas: colour with the contact shading baked in, roughness, and a glow mask. The colour map holds no type
colour: the type is the glow's tint, so one atlas serves all five.

The light is designed first, as the sheet shows it: 1 on the lit edges and on the masks' cuts; on the coat, the
sleeves and the legs it rises toward their lit edge, as light through paper: a lantern's hoops show in it as darker
lines, and the paper's grain. The collar and the hollows stay dark.

Roblox multiplies a surface's glow by its colour map: (mask x EmissiveStrength x EmissiveTint + light) x colour.
So the glow mask that's written is that design divided by the colour under it (encode()), the colour map is a
neutral tone under the lit edges, and the cloth loses its violet where light comes through it, or it would filter
the type's colour. The body and the masks each have their own EmissiveStrength, in the recipe.

Writes to <out_dir>: Shade_<Piece>.json (blcommon.export_mesh_json), Shade_<Map>.png, Shade.recipe.json,
shade_model.blend, shade_model_sheet.png and shade_atlas_check.png. The shapes come from shade_sheet.build(), the
unwrap and the review's tools from rook_model.py. The bake is Cycles, under build/locks/blender.lock.
"""
import json
import math
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_sheet as ss  # noqa: E402

SIZE, APART, STRIP, MARGIN = rm.SIZE, rm.APART, rm.STRIP, rm.MARGIN
BODY = {"root": "Torso", "rs": "RightArm", "ls": "LeftArm", "rh": "RightLeg", "lh": "LeftLeg"}
R6 = {"Torso": "Torso", "RightArm": "Right Arm", "LeftArm": "Left Arm", "RightLeg": "Right Leg", "LeftLeg": "Left Leg"}
FIRST = "Brawler"
PIECES = [*BODY.values(), *(f"Mask{kind}" for kind in ss.MASKS)]
# surface: roughness. Nothing here is metal, so there's no metalness map.
SURFACES = {"Void": 0.92, "VoidLift": 0.9, "Paper": 0.82, "PaperShade": 0.86, "Ink": 0.55, "Glow": 0.6}
LIT = ("Glow",)
CLOTH = ("Void", "VoidLift")
UNLIT = "#505050"  # the colour map under the body's lit edges: neutral, so the type's colour comes through whole,
                   # and dark, so daylight doesn't wash the edge out
CUT = "#F0F0F0"    # under a mask's cuts: they're lit white, and white by day
GROUND = "Void"    # the colour map's tone past the islands
SHADE = rm.SHADE
LIGHT = 2.0        # a lit edge's light as designed: what the glow adds to the picture, in the type's colour
HOT = 32.0         # the body's EmissiveStrength: high, because the cloth under its glow is nearly black
MASK_HOT = 12.0    # a mask's: lower, so the faint glow on its pale paper keeps enough steps in 8 bits
PAPER = ("Paper", "PaperShade")
PAPER_GLOW = 0.2   # the light on a mask's paper: at dusk it reads as paper, not slate (research's read of the model)
NEUTRAL = 0.05     # the cloth's light at which its colour has lost all its violet
FULL = 0.9         # the most the glow mask is asked for on the cloth: the colour under it is lifted to that
LUMA = np.array((0.2126, 0.7152, 0.0722), dtype=np.float32)
MASK_TINT = "#FFE2B8"  # a mask's own EmissiveTint, a warm white: its paper and its cuts. The body's tint is the type
# The light through the cloth, by piece: (the lit edge's height, how far up it reaches, its most, the piece's own
# middle in x). Studs, as the piece stands in the model. The legs glow less: they stand under the coat.
WITHIN = {"Torso": (1.93, 1.75, 0.12, 0.0), "RightArm": (2.12, 1.35, 0.12, 1.65), "LeftArm": (2.12, 1.35, 0.12, -1.65),
          "RightLeg": (0.21, 1.2, 0.07, 0.5), "LeftLeg": (0.21, 1.2, 0.07, -0.5)}
HOOP = 0.42        # studs between a lantern's hoops


# --- the pieces ---------------------------------------------------------------------------------------------

def surfaces(materials):
    for name, rough in SURFACES.items():
        m = materials[name]
        if not (m.node_tree and m.node_tree.nodes.get("Principled BSDF")):
            m.use_nodes = True
        bsdf = m.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = rs.srgb(UNLIT) if name in LIT else tuple(m.diffuse_color)
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = 0.0


def take_pieces(scene, materials):
    """The blockout's objects by piece, standing free in the model's frame: the body's five, and all four masks."""
    joints = ss.build(scene, FIRST, materials)
    groups = {part: [o for o in joints[key].children if o.type == "MESH"] for key, part in BODY.items()}
    groups[f"Mask{FIRST}"] = [o for o in joints["neck"].children if o.type == "MESH"]
    for kind in ss.MASKS:
        if kind != FIRST:
            groups[f"Mask{kind}"] = ss.mask(kind, materials)
    for objs in groups.values():
        for o in objs:
            o.parent = None
            o.matrix_world = Matrix.Identity(4)
            bl.smooth_by_angle(o, 32)
    return joints, groups


# --- the bake -------------------------------------------------------------------------------------------------

class _Probing:
    """While active, every material emits where it is: (x + 5, y + 5) / 100 and (z + 1) / 10, for a float bake."""

    def __init__(self, materials):
        self.materials, self.saved = materials, []

    def __enter__(self):
        for material in self.materials:
            tree = material.node_tree
            output = next(n for n in tree.nodes if n.type == "OUTPUT_MATERIAL")
            surface = output.inputs["Surface"]
            previous = surface.links[0].from_socket if surface.links else None
            where = tree.nodes.new("ShaderNodeNewGeometry")
            add = tree.nodes.new("ShaderNodeVectorMath")
            add.operation = "ADD"
            add.inputs[1].default_value = (5.0, 5.0, 1.0)
            scale = tree.nodes.new("ShaderNodeVectorMath")
            scale.operation = "MULTIPLY"
            scale.inputs[1].default_value = (0.01, 0.01, 0.1)
            emission = tree.nodes.new("ShaderNodeEmission")
            tree.links.new(where.outputs["Position"], add.inputs[0])
            tree.links.new(add.outputs["Vector"], scale.inputs[0])
            tree.links.new(scale.outputs["Vector"], emission.inputs["Color"])
            tree.links.new(emission.outputs["Emission"], surface)
            self.saved.append((tree, surface, previous, (where, add, scale, emission)))
        return self

    def __exit__(self, *_):
        for tree, surface, previous, made in self.saved:
            for node in made:
                tree.nodes.remove(node)
            if previous:
                tree.links.new(previous, surface)


def through_paper(probe, cloth):
    """The glow mask's share on the cloth: for each texel, from where it is on its piece."""
    x, y, z = probe[..., 0] * 100 - 5, probe[..., 1] * 100 - 5, probe[..., 2] * 10 - 1
    piece = np.rint(x / APART).astype(np.int32)
    glow = np.zeros(x.shape, dtype=np.float32)
    for name, (edge, reach, most, middle) in WITHIN.items():
        index = PIECES.index(name)
        t = np.clip((z - edge) / reach, 0, 1)
        g = most * (1 - t) ** 1.7
        phase = ((z - edge) / HOOP) % 1.0
        g *= 1 - 0.5 * np.clip((np.abs(phase - 0.5) - 0.41) / 0.04, 0, 1)   # a hoop: a thin darker line
        a = np.arctan2(y, x - index * APART - middle)
        g *= 1 + 0.16 * np.sin(a * 41 + z * 2.3) * np.sin(a * 97 - z * 1.1)  # the grain, running down
        glow = np.where(cloth & (piece == index), g, glow)
    return glow.astype(np.float32)


def linear(c):
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def coded(c):
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * np.clip(c, 0, None) ** (1 / 2.4) - 0.055)


def unviolet(colour, light):
    """The colour map where light comes through the cloth: without its hue, and no darker than the body's strength
    can light. The glow is drawn through this colour, so a violet coat would turn a green Shade's light teal, and a
    crevice's dark would put the light out where it's meant to be most."""
    lin = linear(colour[..., :3])
    grey = (lin @ LUMA)[..., None]
    w = np.clip(light / NEUTRAL, 0, 1)[..., None]
    least = (light * LIGHT / (HOT * FULL))[..., None]
    colour[..., :3] = coded(np.maximum(lin * (1 - w) + grey * w, least))


def encode(light, colour, hot):
    """The glow mask Roblox needs to draw the designed light: the light over the strength and over the colour map
    under it. Where the colour is too dark for the strength, the mask stops at 1 and the light falls short."""
    under = np.maximum(linear(colour[..., :3]) @ LUMA, 1e-4)
    return np.clip(light * LIGHT / (hot * under), 0, 1)


def bake(obj, out):
    """The maps, with the contact shading multiplied into the colour, the light through the cloth added to the
    light on the edges, the strip's swatches painted in, and the light encoded as Roblox's glow mask."""
    scene = bpy.context.scene
    world = bpy.data.worlds.new("Bake")
    scene.world = world
    world.light_settings.distance = 1.2
    held = rm.lock("shade_model.py")
    try:
        paths = bl.bake_pbr(obj, SIZE, out, "Shade", samples=16, emissive=LIT, margin=MARGIN, fill=True)
        used = [slot.material for slot in obj.material_slots if slot.material]
        extra = {}
        for name, real in (("Cover", False), ("Cloth", False), ("Paper", False), ("Shade", False), ("Probe", True)):
            extra[name] = bpy.data.images.new(f"Shade_{name}_", SIZE, SIZE, alpha=False, float_buffer=real)
            extra[name].colorspace_settings.name = "Non-Color"

        def onto(name):
            for m in used:
                m.node_tree.nodes.active.image = extra[name]

        onto("Cover")
        with bl._Glowing(used, [m.name for m in used]):  # white on the islands and their margin
            bpy.ops.object.bake(type="EMIT", use_clear=True)
        onto("Cloth")
        with bl._Glowing(used, CLOTH):
            bpy.ops.object.bake(type="EMIT", use_clear=True)
        onto("Paper")
        with bl._Glowing(used, PAPER):
            bpy.ops.object.bake(type="EMIT", use_clear=True)
        onto("Probe")
        with _Probing(used):
            bpy.ops.object.bake(type="EMIT", use_clear=True)
        onto("Shade")
        scene.cycles.samples = 256
        bpy.ops.object.bake(type="AO", use_clear=True)
    finally:
        held.unlink(missing_ok=True)
    covered = rm.pixels(extra["Cover"])[..., 0] > 0.5
    for _ in range(2):  # 2 px in, as the kit's fill does: the mask's edge runs a pixel past the margin
        inner = covered.copy()
        inner[1:, :] &= covered[:-1, :]
        inner[:-1, :] &= covered[1:, :]
        inner[:, 1:] &= covered[:, :-1]
        inner[:, :-1] &= covered[:, 1:]
        covered = inner
    ao = rm.pixels(extra["Shade"])[..., :1] ** 0.85
    images = {kind: bpy.data.images[f"Shade_{kind}"] for kind in paths}
    colour = rm.pixels(images["Color"])
    glow = rm.pixels(images["Emissive"])
    lit = glow[..., :1] > 0.5  # no contact shading under a lit edge: the glow is drawn through the colour
    colour[..., :3] *= SHADE + (1 - SHADE) * np.where(covered[..., None] & ~lit, ao, 1.0)
    probe = rm.pixels(extra["Probe"])
    on_mask = covered & (np.rint((probe[..., 0] * 100 - 5) / APART) >= len(BODY))
    colour[lit[..., 0] & on_mask, :3] = rs.rgb(CUT)
    colour[~covered, :3] = rs.rgb(ss.PALETTE[GROUND])  # past the islands: one tone, never the shade's dark
    cloth = covered & (rm.pixels(extra["Cloth"])[..., 0] > 0.5)
    within = through_paper(probe, cloth)
    unviolet(colour, within)
    glow[..., :3] = np.maximum(glow[..., :3], within[..., None])
    paper = covered & (rm.pixels(extra["Paper"])[..., 0] > 0.5)
    glow[paper, :3] = np.maximum(glow[paper, :3], PAPER_GLOW)
    rows = int(STRIP * 0.8 * SIZE)
    maps = {"Color": colour, "Roughness": rm.pixels(images["Roughness"]), "Emissive": glow}
    for i, (name, rough) in enumerate(SURFACES.items()):
        x0, x1 = round(i * SIZE / len(SURFACES)), round((i + 1) * SIZE / len(SURFACES))
        code = UNLIT if name in LIT else ss.PALETTE[name]
        for kind, value in (("Color", rs.rgb(code)), ("Roughness", rough), ("Emissive", PAPER_GLOW if name in PAPER else 0.0)):
            maps[kind][:rows, x0:x1, :3] = value
    on_mask[:rows] = True  # the swatches that glow are paper, and only a mask wears paper
    light = glow[..., 0].copy()
    glow[..., :3] = encode(light, colour, np.where(on_mask, MASK_HOT, HOT))[..., None]
    short = (light > 0) & (glow[..., 0] >= 1) & covered
    lost = 1 - (np.where(on_mask, MASK_HOT, HOT) * (linear(colour[..., :3]) @ LUMA))[short] / (light[short] * LIGHT)
    print(f"glow mask: {short.sum()} texels stop at 1 ({100 * short.sum() / max(1, (light > 0).sum()):.1f}% of the lit), "
          f"losing {100 * lost.mean() if short.any() else 0:.0f}% of their light on average")
    for kind, data in maps.items():
        images[kind].pixels.foreach_set(data.ravel())
        images[kind].save()
    for kind in ("Normal", "Metalness"):  # flat, and nothing is metal
        paths.pop(kind).unlink()
    return paths


def split(obj):
    """The baked mesh cut back into its pieces, each where it stands in the model."""
    made = {}
    for index, piece in enumerate(PIECES):
        mesh = obj.data.copy()
        bm = bmesh.new()
        bm.from_mesh(mesh)
        layer = bm.faces.layers.int["piece"]
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if f[layer] != index], context="FACES")
        bm.to_mesh(mesh)
        bm.free()
        mesh.transform(Matrix.Translation((-APART * index, 0, 0)))
        o = bpy.data.objects.new(f"Shade_{piece}", mesh)
        mesh.name = o.name
        bpy.context.scene.collection.objects.link(o)
        made[piece] = o
    bpy.data.objects.remove(obj, do_unlink=True)
    return made


def baked(name, paths):
    """What Roblox will draw: the maps on one surface, the glow mask in a type's colour and through the colour map,
    as the engine multiplies it. Returns the material and the way to set its type and its strength."""
    m = bpy.data.materials.new(name)
    if not (m.node_tree and m.node_tree.nodes.get("Principled BSDF")):
        m.use_nodes = True
    bsdf, nodes, links = bl._principled(m)

    def texture(kind, data):
        node = nodes.new("ShaderNodeTexImage")
        node.image = bpy.data.images.load(str(paths[kind]), check_existing=True)
        if data:
            node.image.colorspace_settings.name = "Non-Color"
        return node.outputs["Color"]

    colour_map = texture("Color", False)
    links.new(colour_map, bsdf.inputs["Base Color"])
    tinted = nodes.new("ShaderNodeMix")
    tinted.data_type, tinted.blend_type = "RGBA", "MULTIPLY"
    tinted.inputs[0].default_value = 1.0
    links.new(colour_map, tinted.inputs[6])
    links.new(tinted.outputs[2], bsdf.inputs["Emission Color"])
    links.new(texture("Roughness", True), bsdf.inputs["Roughness"])
    strength = nodes.new("ShaderNodeMath")
    strength.operation = "MULTIPLY"
    links.new(texture("Emissive", True), strength.inputs[0])
    links.new(strength.outputs[0], bsdf.inputs["Emission Strength"])
    m.diffuse_color = (0.62, 0.6, 0.58, 1)  # the clay, in Workbench

    def light(colour, hot=HOT):
        tinted.inputs[7].default_value = rs.srgb(ss.TYPES.get(colour, colour))
        strength.inputs[1].default_value = hot

    return m, light


def pose_stride(joints):
    """Hung, with the left leg swung back and the right forward: a walk's widest, to show a lifted leg's end."""
    ss.pose_hung(joints)
    body = joints["root"].rotation_quaternion.copy()
    rs.aim(joints["lh"], body, (0.0, -0.62, -1.0))
    rs.aim(joints["rh"], body, (0.0, 0.5, -1.0))
    rs.stand_on_floor(joints)


POSES = {**ss.POSES, "stride": pose_stride}
BELOW = (150, -58)   # from under the floor, in front
BEHIND = (22, -4)    # from behind and low: what a lifted leg shows of its end


# --- the hand-off -----------------------------------------------------------------------------------------------

def export(made, paths, out, density):
    """Each piece as JSON for Studio, and the recipe's facts. Points are Roblox's: studs, Y up, the model standing
    on y = 0 and facing -Z, its HumanoidRootPart at (0, 3, 0)."""
    body, masks, total = [], {}, 0
    for piece, o in made.items():
        tris = bl.export_mesh_json(o, out / f"{o.name}.json")
        box = [v.co for v in o.data.vertices]
        size = [round(max(c[i] for c in box) - min(c[i] for c in box), 3) for i in (0, 2, 1)]
        entry = {"name": o.name, "mesh": f"{o.name}.json", "on": R6.get(piece, "Head"),
                 "centre": json.loads((out / f"{o.name}.json").read_text())["c"], "size": size, "tris": tris}
        print(f"{o.name}: {tris} tris, {size} studs")
        if piece in R6:
            body.append(entry)
            total += tris
        else:
            kind = piece[4:]
            masks[kind] = {**entry, "type": ss.MASKS[kind][0], "top": round(max(c.z for c in box), 2)}
    recipe = {
        "name": "Shade",
        "frame": "Roblox studs: Y up, the model on y = 0 facing -Z, HumanoidRootPart at (0, 3, 0)",
        "rig": "R6. Every piece carries the body's own surface: the six rig parts are hidden (Transparency 1). "
               "The Head carries one mask and nothing else.",
        "maps": {kind: path.name for kind, path in paths.items()},
        "texels_per_stud": round(density),
        "emissive": {"strength": HOT, "mask_strength": MASK_HOT, "tints": ss.TYPES, "mask_tint": MASK_TINT,
                     "note": "One atlas for the five types. The body's five pieces take the type as EmissiveTint and "
                             "strength as EmissiveStrength. The mask, its own MeshPart with its own SurfaceAppearance, "
                             "takes mask_tint whatever the type and mask_strength: its paper glows faintly and its "
                             "cuts are lit in that warm white, so it reads as paper at dusk. Roblox draws (mask x "
                             "strength x tint + light) x colour map, so the glow mask is written for these two "
                             "strengths and this colour map: change a strength and every glow scales with it, upload "
                             "the two maps together. The colour map is a neutral grey under the lit edges and loses "
                             "its violet where light comes through the cloth. The tints are the sheet's proposal "
                             "until AR3's gems fix them, and the mask's is tuned in the engine under the game's "
                             "lighting."},
        "pieces": body,
        "masks": masks,
        "points": [{"name": "Chest", "on": "Torso", "at": rm.roblox((0, 0.6, 3.0)), "note": "where a hit lands"},
                   {"name": "Crest", "on": "Torso", "at": rm.roblox((0, -0.62, 3.0)), "note": "the lit mark on its back"}],
        "tris": {"body": total, **{kind: total + entry["tris"] for kind, entry in masks.items()}},
    }
    (out / "Shade.recipe.json").write_text(json.dumps(recipe, indent=1))
    return recipe


# --- the review -------------------------------------------------------------------------------------------------

def lighting(scene, azimuth, dusk):
    """The dusk it's met in, or a plain day: the sun over the camera's left shoulder either way."""
    rm.sun_for(scene, azimuth)
    sun = bpy.data.objects["Sun"].data
    background = scene.world.node_tree.nodes["Background"]
    if dusk:
        sun.energy, sun.color = 1.9, (0.72, 0.78, 1.0)
        background.inputs["Color"].default_value = (0.16, 0.17, 0.4, 1)
        background.inputs["Strength"].default_value = 0.8
    else:
        sun.energy, sun.color = 3.2, (1.0, 1.0, 1.0)


def review(joints, made, paths, recipe, out, facts):
    scene = bpy.context.scene
    look, light = baked("Shade_Baked", paths)
    mask_look, mask_light = baked("Shade_Mask", paths)
    mask_light(MASK_TINT, MASK_HOT)
    for piece, o in made.items():
        bl.assign_only(o, look if piece in R6 else mask_look)
    bl.save_blend(out / "shade_model.blend")  # the pieces standing free in the model's frame, for the clips' rig
    for piece, o in made.items():
        key = next((k for k, part in BODY.items() if part == piece), "neck")
        o.parent = joints[key]
        o.matrix_parent_inverse = Matrix.Translation(-Vector(rs.PIVOTS[key]))
    centre, span, px = (0, 0, 3.0), 8.0, 640
    shots = {}

    def take(name, pose, view, kind=FIRST, colour="Strength", dusk=True, clay=False, at=centre, across=span, size=px):
        rm.rest(joints)
        for k in ss.MASKS:
            made[f"Mask{k}"].hide_render = k != kind
        POSES[pose](joints)
        light(colour)
        if clay:
            rs.workbench(scene, size, size)
        else:
            rm.eevee(scene, size, size)
            lighting(scene, view[0], dusk)
        path = out / f"_{name}.png"
        shots[name] = rs.shoot(scene, path, view[0], view[1], at, across)
        path.unlink()

    take("front", "square", ss.FRONT)
    take("back", "square", ss.BACK)
    take("side", "hung", ss.SIDE)
    take("quarter", "hung", ss.QUARTER)
    take("day", "hung", ss.PLAYER, dusk=False)
    take("above", "hung", ss.ABOVE)
    take("below", "square", BELOW)
    take("stride", "stride", BEHIND)
    take("stridebright", "stride", BEHIND, dusk=False)
    for kind, (colour, _) in ss.MASKS.items():
        take(f"bust{kind}", "hung", ss.BUST, kind, colour, at=(0, 0, 4.9), across=3.8, size=520)
        take(f"player{kind}", "hung", ss.PLAYER, kind, colour)
        take(f"bright{kind}", "hung", ss.PLAYER, kind, colour, dusk=False)
    for colour in ss.TYPES:
        take(f"type{colour}", "hung", ss.BUST, colour=colour)

    W, H = 1920, 1130
    ink, soft, pale = "#1E1B22", "#6A6670", "#B9B4C6"
    page = rs.canvas(W, H, rs.PAPER)
    text = [(30, 24, 30, "SHADE, the model on R6", ink),
            (30, 62, 15, "AR2, delivery 2. Lit as the baked maps draw: at dusk, and by day. No bloom: the game's, if any, is the builder's.", soft)]
    top, floor, k = 96, 462, 0.56
    rs.fill(page, 20, top, 1570, 400, rs.NIGHT)
    rs.fill(page, 1590, top, 310, 400, rs.DAY)
    for i, (name, label) in enumerate((("front", "front, standing square"), ("back", "back"), ("side", "side: nothing behind the mask"),
                                       ("quarter", "three-quarter, how it stands"), ("playerBrawler", "the player's camera"),
                                       ("day", "the same, by day"))):
        x = 24 + i * 314
        rs.stand(page, rs.shrink(shots[name], k), x, floor, 306)
        text.append((x + 12, floor + 12, 14, label, soft if name == "day" else pale))

    text.append((30, 512, 20, "The four masks", ink))
    y = 546
    for i, (kind, (colour, words)) in enumerate(ss.MASKS.items()):
        x = 30 + i * 290
        rs.fill(page, x, y, 274, 274, rs.NIGHT)
        rs.paste(page, rs.shrink(shots[f"bust{kind}"], 274 / 520), x, y)
        text.append((x + 2, y + 282, 14, f"{kind}: {words} ({colour})", soft))
    x0 = 1200
    text.append((x0, 512, 20, "The five types: one atlas, the glow's tint", ink))
    rs.fill(page, x0, y, 700, 274, rs.NIGHT)
    for i, colour in enumerate(ss.TYPES):
        rs.stand(page, rs.shrink(shots[f"type{colour}"], 0.36), x0 + 4 + i * 139, y + 266, 136)
        text.append((x0 + 12 + i * 139, y + 8, 13, colour, pale))

    # the 64 px read: a 5 stud body 64 px tall, from the player's camera, at dusk, by day, and as outlines
    y = 880
    f64 = 64 / (5 * px / span)
    text.append((30, y - 26, 15, "at 64 px, from the player's camera", soft))
    for r, (ground, how) in enumerate(((rs.NIGHT, "player"), (rs.DAY, "bright"), (rs.PAPER, "outline"))):
        rs.fill(page, 30, y + r * 70, 420, 68, ground)
        for c, kind in enumerate(ss.MASKS):
            shot = rs.shrink(shots[f"{'player' if how == 'outline' else how}{kind}"], f64)
            rs.stand(page, rs.black(shot) if how == "outline" else shot, 36 + c * 104, y + r * 70 + 67, 100)
    x1 = 480
    text.append((x1, y - 26, 15, "from behind and above", soft))
    rs.fill(page, x1, y, 220, 208, rs.NIGHT)
    rs.stand(page, rs.shrink(shots["above"], 0.33), x1, y + 204, 150)
    rs.stand(page, rs.shrink(shots["above"], f64), x1 + 150, y + 204, 64)
    x2 = 716
    text.append((x2, y - 26, 15, "from below, and a leg lifted", soft))
    rs.fill(page, x2, y, 440, 208, rs.NIGHT)
    rs.fill(page, x2 + 440, y, 76, 208, rs.DAY)
    rs.stand(page, rs.shrink(shots["below"], 0.33), x2, y + 204, 170)
    rs.stand(page, rs.shrink(shots["stride"], 0.33), x2 + 170, y + 204, 150)
    for i, name in enumerate(("below", "stride")):
        rs.stand(page, rs.shrink(shots[name], f64), x2 + 318 + i * 60, y + 204, 60)
    rs.stand(page, rs.shrink(shots["stridebright"], f64), x2 + 446, y + 204, 64)
    x3 = 1250
    for i, (kind, label) in enumerate((("Color", "the colour map, 1024 px"), ("Emissive", "the glow mask"))):
        atlas = rs.load(paths[kind])
        atlas[..., 3] = 1.0
        rs.paste(page, rs.shrink(atlas, 150 / SIZE), x3 + i * 162, y)
        text.append((x3 + i * 162, y + 156, 12, label, soft))
    for i, line in enumerate(facts):
        text.append((1584, y - 4 + i * 21, 12, line, ink))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "shade_model_sheet.png")
    rs.save(rs.shrink(page, 0.5), out / "shade_model_sheet_small.png")


def atlas_check(paths, out):
    """The maps as they upload, for the content check: whole, and at 64 px on a dark and a bright ground."""
    page = rs.canvas(SIZE * 2 + 60, SIZE + 260, rs.NIGHT)
    soft = "#9A9CA8"
    text = []
    for i, kind in enumerate(("Color", "Emissive")):
        atlas = rs.load(paths[kind])
        atlas[..., 3] = 1.0
        x = 20 + i * (SIZE + 20)
        rs.paste(page, atlas, x, 20)
        small = rs.shrink(atlas, 64 / SIZE)
        rs.fill(page, x + 100, SIZE + 60, 104, 104, rs.DAY)
        rs.paste(page, small, x, SIZE + 80)
        rs.paste(page, small, x + 120, SIZE + 80)
        rs.paste(page, rs.shrink(atlas, 180 / SIZE), x + 240, SIZE + 60)
        text.append((x, SIZE + 44, 13, f"{paths[kind].name}: 64 px on dark and on bright, and at 180 px", soft))
    rs.paste(page, rs.text_layer(page.shape[1], page.shape[0], text), 0, 0)
    rs.save(page, out / "shade_atlas_check.png")


def main():
    out = bl.out_dir()
    rs.OUT = out
    scene = bl.reset_scene()
    materials = ss.materials("Strength")
    surfaces(materials)
    ss.SHIPPED_PACK = True  # the Brawler's cuts packed as shipped, then moved to today's shapes (AR47)
    joints, groups = take_pieces(scene, materials)
    hidden = total = 0
    for index, piece in enumerate(PIECES):
        h, t = rm.mark_faces(groups[piece], index)
        hidden, total = hidden + h, total + t
        for o in groups[piece]:
            o.data.transform(Matrix.Translation((APART * index, 0, 0)))
    whole = bl.join([o for piece in PIECES for o in groups[piece]], "Shade")
    area, density = rm.unwrap(whole, SURFACES, LIT)
    print(f"faces {total}, unseen {hidden}; seen area {area:.1f} sq studs; {density:.0f} px per stud at {SIZE}")
    print(f"settled: {ss.settle(whole)} points of the Brawler's cuts and teeth moved to today's shapes")
    paths = bake(whole, out)
    made = split(whole)
    recipe = export(made, paths, out, density)
    tris = recipe["tris"]
    pts = [v.co for piece in R6 for v in made[piece].data.vertices]
    facts = [f"{tris['body']} triangles in the body's 5 pieces",
             "with its mask: " + ", ".join(f"{kind} {tris[kind]}" for kind in ss.MASKS),
             f"{max(p.x for p in pts) - min(p.x for p in pts):.2f} studs wide, 4.64 to the collar's rim",
             "to the mask's top: " + ", ".join(f"{kind} {entry['top']}" for kind, entry in recipe["masks"].items()),
             f"one {SIZE} px atlas, {density:.0f} px per stud",
             "maps: colour, roughness, glow mask",
             "no extra joints: the mask rides the Head",
             f"the light: 1 on the lit edges, to {WITHIN['Torso'][2]} on the cloth",
             f"EmissiveStrength {HOT:g}, a mask's {MASK_HOT:g}"]
    print("; ".join(facts))
    review(joints, made, paths, recipe, out, facts)
    atlas_check(paths, out)


if __name__ == "__main__":
    main()
