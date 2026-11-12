"""Rook's model (AR1, delivery 2): his pieces on the R6 rig, one baked texture set, the exports and the review sheet.

blender.exe -b --factory-startup --python tools/blender/rook_model.py -- <out_dir>

How he sits on R6: a rigid mesh for each of the six parts, which carries the body's own surface too, so the rig's
blocks are hidden; and two pieces on joints of their own, the gauntlet's piston (it slides along the arm) and the loose
tape ends (they swing). Everything shares one 1024 px atlas: colour with the contact shading baked in, roughness,
metalness, and a mask over the knuckles, the heat band and the piston's rod, which the game lights through the wind-up.
No normal map: the low mesh is the form, and a bake of it is flat.

Writes to <out_dir>: Rook_<Piece>.json (blcommon.export_mesh_json), Rook_<Map>.png, Rook.recipe.json (what the
builder's recipe needs: which part each piece rides, the joints' pivots, the points the game reads), rook_model.blend
and rook_model_sheet.png. The shapes come from rook_sheet.build(). The bake is Cycles, under build/locks/blender.lock.
"""
import json
import math
import sys
import time
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402

SIZE = 1024
APART = 10.0  # studs between the pieces while they bake, so no piece shades another
STRIP = 0.04
SMALL = 20    # px: an island narrower than this, or under its square in area, is parked on its surface's swatch
MARGIN = 8    # px each island is padded by
GROUND = "Iron"  # the colour map's tone past the islands
# STRIP: the atlas's bottom strip: one swatch per surface, where the faces nothing can see are parked
JOINTS = {"root": "Torso", "neck": "Head", "rs": "RightArm", "ls": "LeftArm", "rh": "RightLeg", "lh": "LeftLeg"}
R6 = {"Torso": "Torso", "Head": "Head", "RightArm": "Right Arm", "LeftArm": "Left Arm", "RightLeg": "Right Leg",
      "LeftLeg": "Left Leg"}
MOTORS = {"Piston": ("RightArm", ("PistonRod", "PistonCap")), "Tape": ("LeftArm", ("TapeEnd",))}
PIECES = [*JOINTS.values(), *MOTORS]
TRAVEL = 0.65  # how far the piston draws out, studs along the arm

# surface: (roughness, metalness). The iron keeps most of its own colour: full metal goes black wherever the sky is.
SURFACES = {
    "Oxblood": (0.82, 0.0), "OxbloodDeep": (0.85, 0.0), "Bone": (0.9, 0.0), "BoneShade": (0.9, 0.0),
    "Ember": (0.35, 0.0), "Ink": (0.5, 0.0), "Charcoal": (0.88, 0.0), "Iron": (0.42, 0.35), "IronDeep": (0.5, 0.35),
    "Steel": (0.3, 0.6), "Glow": (0.3, 0.6), "Skin": (0.65, 0.0), "SkinShade": (0.65, 0.0),
}
LIT = ("Ember", "Glow")
BEVELS = {"Hair": 0.035, "CollarMerlon": 0.025, "Knuckle": 0.035, "PistonCap": 0.03, "PistonCase": 0.03, "Bolt": 0.02,
          "Buckle": 0.02}
SHADE = np.array((0.40, 0.34, 0.48), dtype=np.float32)  # what a crevice multiplies the colour by: cool, never grey
HOT = 2.5  # the lit ram's EmissiveStrength


def base(obj):
    return obj.name.split(".")[0]


# --- the pieces ---------------------------------------------------------------------------------------------

def surfaces():
    for name, (rough, metal) in SURFACES.items():
        m = bpy.data.materials[name]
        if not (m.node_tree and m.node_tree.nodes.get("Principled BSDF")):
            m.use_nodes = True
        bsdf = m.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = tuple(m.diffuse_color)
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = metal


def take_pieces(joints):
    """The blockout's objects, by the piece each belongs to, finished and standing free in the model's frame."""
    groups = {piece: [] for piece in PIECES}
    for key, part in JOINTS.items():
        for o in list(joints[key].children):
            if o.type != "MESH":
                continue
            piece = next((m for m, (_, names) in MOTORS.items() if base(o) in names), part)
            groups[piece].append(o)
    for objs in groups.values():
        for o in objs:
            o.parent = None
            o.matrix_world = Matrix.Identity(4)
            if base(o) in BEVELS:
                bl.bevel(o, BEVELS[base(o)], segments=2)
            bl.smooth_by_angle(o, 32)
    return groups


def _dome(count=28):
    """Directions over a hemisphere about +Z, none flatter than 8 degrees."""
    out = []
    for i in range(count):
        z = 0.14 + 0.86 * (i + 0.5) / count
        r, a = math.sqrt(1 - z * z), i * 2.39996
        out.append(Vector((r * math.cos(a), r * math.sin(a), z)))
    return out


DOME = _dome()
UP = Vector((0, 0, 1))


def mark_faces(objs, index):
    """Tags each face with its piece, and with `hidden` when nothing outside the piece can see it: a face sunk in
    another shell of the same piece. Those take no room in the atlas."""
    verts, tris = [], []
    for o in objs:
        first = len(verts)
        verts += [v.co.copy() for v in o.data.vertices]
        o.data.calc_loop_triangles()
        tris += [tuple(first + i for i in t.vertices) for t in o.data.loop_triangles]
    tree = BVHTree.FromPolygons(verts, tris)
    hidden = total = 0
    for o in objs:
        mesh = o.data
        piece = mesh.attributes.new("piece", "INT", "FACE")
        unseen = mesh.attributes.new("unseen", "INT", "FACE")
        for poly in mesh.polygons:
            n = poly.normal
            turn = UP.rotation_difference(n)
            ids = list(poly.vertices)
            points = [poly.center] + [poly.center.lerp(mesh.vertices[i].co, 0.75) for i in ids[::max(1, len(ids) // 6)]]
            seen = any(tree.ray_cast(p + n * 0.003, turn @ d, 40.0)[0] is None for p in points for d in DOME)
            piece.data[poly.index].value = index
            unseen.data[poly.index].value = int(not seen)
            hidden += not seen
            total += 1
    return hidden, total


def face_values(mesh, name):
    values = np.zeros(len(mesh.polygons), dtype=np.int32)
    mesh.attributes[name].data.foreach_get("value", values)
    return values


def project(obj):
    """Unwraps the faces not marked `unseen`."""
    mesh = obj.data
    bl._select_only(obj)
    bpy.ops.object.mode_set(mode="EDIT")
    bm = bmesh.from_edit_mesh(mesh)
    bm.select_mode = {"FACE"}
    layer = bm.faces.layers.int["unseen"]
    for f in bm.faces:
        f.select_set(not f[layer])
    bm.select_flush_mode()
    bmesh.update_edit_mesh(mesh)
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.012)
    bpy.ops.object.mode_set(mode="OBJECT")


def park_small(mesh, lit=LIT):
    """Marks as `unseen` the islands too small to carry shading: they take their surface's swatch. Padded by the
    bake's margin, a small island is a round blob of one colour on the map, which reads as a drop. The lit faces
    stay, since the swatches don't glow. Returns how many faces it parked."""
    from bpy_extras import mesh_utils
    unseen = face_values(mesh, "unseen")
    uv = mesh.uv_layers.active.uv
    parked = 0
    for island in mesh_utils.mesh_linked_uv_islands(mesh):
        faces = [f for f in island if not unseen[f]]
        if not faces or any(mesh.materials[mesh.polygons[f].material_index].name in lit for f in faces):
            continue
        pts = np.array([uv[i].vector[:] for f in faces for i in mesh.polygons[f].loop_indices])
        area = 0.0
        for f in faces:
            q = np.array([uv[i].vector[:] for i in mesh.polygons[f].loop_indices])
            area += abs(np.sum(q[:, 0] * np.roll(q[:, 1], -1) - np.roll(q[:, 0], -1) * q[:, 1])) / 2
        if (pts.max(axis=0) - pts.min(axis=0)).min() * SIZE < SMALL or area * SIZE * SIZE < SMALL * SMALL:
            unseen[faces] = 1
            parked += len(faces)
    mesh.attributes["unseen"].data.foreach_set("value", unseen)
    return parked


def unwrap(obj, surfaces=None, lit=LIT):
    """The faces that show, into one atlas above the strip; the rest onto their surface's swatch in it."""
    mesh = obj.data
    if not mesh.uv_layers:
        mesh.uv_layers.new(name="UVMap")
    project(obj)
    parked = 0
    for _ in range(6):  # again while it finds some: with faces gone, the next projection cuts its islands anew
        more = park_small(mesh, lit)
        if not more:
            break
        parked += more
        project(obj)
    print(f"parked on the swatches: {parked} faces of islands under {SMALL} px")
    unseen = face_values(mesh, "unseen")
    names = list(surfaces or SURFACES)
    uv = mesh.uv_layers.active.uv
    area3, area2 = 0.0, 0.0
    for poly in mesh.polygons:
        loops = range(poly.loop_start, poly.loop_start + poly.loop_total)
        if unseen[poly.index]:
            at = ((names.index(mesh.materials[poly.material_index].name) + 0.5) / len(names), STRIP * 0.4)
            for i in loops:
                uv[i].vector = at
            continue
        for i in loops:
            u, v = uv[i].vector
            uv[i].vector = (u, STRIP + (1 - STRIP) * v)
        pts = [uv[i].vector for i in loops]
        area2 += abs(sum(pts[k].x * pts[(k + 1) % len(pts)].y - pts[(k + 1) % len(pts)].x * pts[k].y for k in range(len(pts)))) / 2
        area3 += poly.area
    return area3, math.sqrt(area2 * SIZE * SIZE / area3)


# --- the bake -------------------------------------------------------------------------------------------------

def lock(who="rook_model.py"):
    path = Path(__file__).resolve().parents[2] / "build" / "locks" / "blender.lock"
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and time.time() - path.stat().st_mtime < 1800:
        raise SystemExit(f"The GPU is held: {path.read_text().strip()}")
    path.write_text(f"Modulo, {who}, {time.strftime('%Y-%m-%d %H:%M')}\n")
    return path


def pixels(image):
    data = np.empty(len(image.pixels), dtype=np.float32)
    image.pixels.foreach_get(data)
    return data.reshape(image.size[1], image.size[0], 4)


def bake(obj, out):
    """The maps, with the contact shading multiplied into the colour and the strip's swatches painted in."""
    scene = bpy.context.scene
    world = bpy.data.worlds.new("Bake")
    scene.world = world
    world.light_settings.distance = 1.2
    held = lock()
    try:
        paths = bl.bake_pbr(obj, SIZE, out, "Rook", samples=16, emissive=LIT, margin=MARGIN, fill=True)
        used = [slot.material for slot in obj.material_slots if slot.material]
        cover = bpy.data.images.new("Rook_Cover", SIZE, SIZE, alpha=False)
        shade = bpy.data.images.new("Rook_Shade", SIZE, SIZE, alpha=False)
        cover.colorspace_settings.name = shade.colorspace_settings.name = "Non-Color"
        for m in used:
            m.node_tree.nodes.active.image = cover
        with bl._Glowing(used, [m.name for m in used]):  # white on the islands and their margin
            bpy.ops.object.bake(type="EMIT", use_clear=True)
        for m in used:
            m.node_tree.nodes.active.image = shade
        scene.cycles.samples = 256
        bpy.ops.object.bake(type="AO", use_clear=True)
    finally:
        held.unlink(missing_ok=True)
    covered = pixels(cover)[..., 0] > 0.5
    for _ in range(2):  # 2 px in, as the kit's fill does: the mask's edge runs a pixel past the margin
        inner = covered.copy()
        inner[1:, :] &= covered[:-1, :]
        inner[:-1, :] &= covered[1:, :]
        inner[:, 1:] &= covered[:, :-1]
        inner[:, :-1] &= covered[:, 1:]
        covered = inner
    ao = pixels(shade)[..., :1] ** 0.85
    images = {kind: bpy.data.images[f"Rook_{kind}"] for kind in paths}
    colour = pixels(images["Color"])
    colour[..., :3] *= SHADE + (1 - SHADE) * np.where(covered[..., None], ao, 1.0)
    colour[~covered, :3] = rs.rgb(rs.PALETTE[GROUND])  # past the islands: one neutral, never the shade's dark
    rows = int(STRIP * 0.8 * SIZE)
    maps = {"Color": colour, **{kind: pixels(images[kind]) for kind in ("Roughness", "Metalness", "Emissive")}}
    for i, (name, (rough, metal)) in enumerate(SURFACES.items()):
        x0, x1 = round(i * SIZE / len(SURFACES)), round((i + 1) * SIZE / len(SURFACES))
        code = rs.PALETTE["Steel" if name == "Glow" else name]
        for kind, value in (("Color", rs.rgb(code)), ("Roughness", rough), ("Metalness", metal), ("Emissive", 0.0)):
            maps[kind][:rows, x0:x1, :3] = value
    for kind, data in maps.items():
        images[kind].pixels.foreach_set(data.ravel())
        images[kind].save()
    paths.pop("Normal").unlink()  # flat: the low mesh is the form
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
        o = bpy.data.objects.new(f"Rook_{piece}", mesh)
        mesh.name = o.name
        bpy.context.scene.collection.objects.link(o)
        made[piece] = o
    bpy.data.objects.remove(obj, do_unlink=True)
    return made


def baked(name, paths, glow):
    """What Roblox will draw: the maps on one surface. `glow` is the mask's strength, in the ram's ember."""
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

    links.new(texture("Color", False), bsdf.inputs["Base Color"])
    links.new(texture("Roughness", True), bsdf.inputs["Roughness"])
    links.new(texture("Metalness", True), bsdf.inputs["Metallic"])
    if glow:
        strength = nodes.new("ShaderNodeMath")
        strength.operation = "MULTIPLY"
        strength.inputs[1].default_value = glow
        links.new(texture("Emissive", True), strength.inputs[0])
        bsdf.inputs["Emission Color"].default_value = rs.srgb(rs.PALETTE["Ember"])
        links.new(strength.outputs[0], bsdf.inputs["Emission Strength"])
    m.diffuse_color = (0.62, 0.6, 0.58, 1)  # the clay, in Workbench
    return m


# --- the hand-off -----------------------------------------------------------------------------------------------

def roblox(p):
    return [round(p[0], 4), round(p[2], 4), round(-p[1], 4)]


def export(made, paths, out, density):
    """Each piece as JSON for Studio, and the recipe's facts. Points are Roblox's: studs, Y up, the model standing
    on y = 0 and facing -Z, its HumanoidRootPart at (0, 3, 0)."""
    wf, df, zb, zf, zw, zc = rs.gauntlet(rs.BASE)
    tape = made["Tape"].data.vertices
    top = max(v.co.z for v in tape)
    root = sum((v.co for v in tape if v.co.z > top - 0.03), Vector()) / sum(1 for v in tape if v.co.z > top - 0.03)
    pivots = {"Piston": Vector((1.72 + wf * 0.12, 0.06 - df * 0.4, zc + 0.2)), "Tape": root}
    pieces, total = [], 0
    for piece, o in made.items():
        tris = bl.export_mesh_json(o, out / f"{o.name}.json")
        total += tris
        box = [v.co for v in o.data.vertices]
        size = [round(max(c[i] for c in box) - min(c[i] for c in box), 3) for i in (0, 2, 1)]
        entry = {"name": o.name, "mesh": f"{o.name}.json", "on": R6[MOTORS[piece][0] if piece in MOTORS else piece],
                 "centre": json.loads((out / f"{o.name}.json").read_text())["c"], "size": size, "tris": tris}
        if piece in MOTORS:
            entry["motor"] = piece
            entry["pivot"] = roblox(pivots[piece])
        pieces.append(entry)
        print(f"{o.name}: {tris} tris, {size} studs")
    recipe = {
        "name": "Rook",
        "frame": "Roblox studs: Y up, the model on y = 0 facing -Z, HumanoidRootPart at (0, 3, 0)",
        "rig": "R6. Every piece carries the body's own surface: the six rig parts are hidden (Transparency 1).",
        "maps": {kind: path.name for kind, path in paths.items()},
        "texels_per_stud": round(density),
        "emissive": {"tint": rs.PALETTE["Ember"], "cold": 0, "hot": HOT, "pieces": ["Rook_RightArm", "Rook_Piston"],
                     "note": "the mask covers the knuckles, the heat band and the piston's rod"},
        "pieces": pieces,
        "motors": {"Piston": {"slides": [0, 1, 0], "travel": TRAVEL, "note": "along the arm, toward the shoulder, through Haymaker's wind-up"},
                   "Tape": {"note": "swings about its pivot: the loose ends trail the arm"}},
        "points": [{"name": "Knuckles", "on": "Right Arm", "at": roblox((1.72, 0.06, zb - 0.22)), "note": "the ram's striking face"},
                   {"name": "RamCentre", "on": "Right Arm", "at": roblox((1.72, 0.06, (zb + zf) / 2))}],
        "tris": total,
    }
    (out / "Rook.recipe.json").write_text(json.dumps(recipe, indent=1))
    return recipe


# --- the review -------------------------------------------------------------------------------------------------

def eevee(scene, width, height):
    r = scene.render
    for engine in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
        try:
            r.engine = engine
            break
        except TypeError:
            continue
    r.resolution_x, r.resolution_y, r.resolution_percentage = width, height, 100
    r.film_transparent = True
    r.image_settings.file_format = "PNG"
    r.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    world = scene.world
    if not (world.node_tree and world.node_tree.nodes.get("Background")):
        world.use_nodes = True
    background = world.node_tree.nodes["Background"]
    background.inputs["Color"].default_value = (0.62, 0.68, 0.8, 1)
    background.inputs["Strength"].default_value = 0.55


def sun_for(scene, azimuth):
    """A sun over the camera's left shoulder, so every view is lit the same way."""
    sun = bpy.data.objects.get("Sun")
    if sun is None:
        sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
        sun.data.energy = 3.2
        sun.data.angle = math.radians(6)
        scene.collection.objects.link(sun)
    a, e = math.radians(azimuth - 38), math.radians(48)
    offset = Vector((math.cos(e) * math.sin(a), -math.cos(e) * math.cos(a), math.sin(e)))
    sun.rotation_euler = (-offset).to_track_quat("-Z", "Y").to_euler()


def rest(joints):
    for key, j in joints.items():
        j.rotation_quaternion = (1, 0, 0, 0)
    joints["root"].location = rs.PIVOTS["root"]


def review(joints, made, paths, recipe, out, facts):
    scene = bpy.context.scene
    cold, hot = baked("Rook_Cold", paths, 0.0), baked("Rook_Hot", paths, 1.4)  # 1.4: the preview's own, short of white
    for o in made.values():
        bl.assign_only(o, cold)
    bl.save_blend(out / "rook_model.blend")  # the pieces standing free in the model's frame, for the clips' rig
    for piece, o in made.items():
        key = next(k for k, part in JOINTS.items() if part == (MOTORS[piece][0] if piece in MOTORS else piece))
        o.parent = joints[key]
        o.matrix_parent_inverse = Matrix.Translation(-Vector(rs.PIVOTS[key]))
    centre, span, px = (0, 0, 3.0), 7.4, 640
    shots = {}

    def take(name, pose, view, lit=True, at=centre, across=span, size=px):
        rest(joints)
        rs.POSES[pose](joints)
        wound = pose == "windup"
        made["Piston"].location = (0, 0, TRAVEL if wound else 0)
        for piece, o in made.items():
            bl.assign_only(o, hot if wound and piece in ("RightArm", "Piston") else cold)
        if lit:
            eevee(scene, size, size)
            sun_for(scene, view[0])
        else:
            rs.workbench(scene, size, size)
        path = out / f"_{name}.png"
        shots[name] = rs.shoot(scene, path, view[0], view[1], at, across)
        path.unlink()

    take("front", "square", (180, 6))
    take("back", "square", (0, 6))
    take("side", "square", (90, 6))
    take("quarter", "idle", rs.FRONT)
    take("game", "idle", rs.GAME)
    take("flinch", "windup", rs.FLINCH)
    take("wound", "windup", rs.GAME)
    take("clay", "idle", rs.FRONT, lit=False)
    take("head", "idle", (158, 4), at=(0.1, 0, 4.72), across=2.3, size=520)
    take("ram", "idle", (118, 10), at=(1.6, 0, 2.5), across=3.4, size=520)

    W, H = 1920, 1000
    ink, soft = "#1E1B22", "#6A6670"
    page = rs.canvas(W, H, rs.PAPER)
    text = [(30, 24, 30, "ROOK, the model on R6", ink),
            (30, 62, 15, "AR1, delivery 2. Lit as the baked maps draw, the sun over the camera's left shoulder.", soft)]
    k = 0.66
    for i, (name, label) in enumerate((("front", "front"), ("back", "back"), ("side", "his right side"),
                                       ("quarter", "three-quarter, how he stands"), ("game", "the player's camera"))):
        x = 10 + i * 322
        rs.stand(page, rs.shrink(shots[name], k), x, 500, 322)
        text.append((x + 20, 510, 14, label, soft))
    for i, (name, label, kk) in enumerate((("flinch", "Haymaker's wind-up, the ram lit", 0.62), ("wound", "the same, the player's camera", 0.62),
                                           ("clay", "the form alone", 0.6))):
        x = 10 + i * 340
        rs.stand(page, rs.shrink(shots[name], kk), x, 950, 340)
        text.append((x + 20, 960, 14, label, soft))
    for i, (name, label) in enumerate((("head", "the head, as the reveal shows it"), ("ram", "the ram and its piston"))):
        x = 1040 + i * 290
        rs.stand(page, rs.shrink(shots[name], 0.54), x, 950, 290)
        text.append((x + 20, 960, 14, label, soft))
    # the 64 px read: a 5 stud body 64 px tall, over a dark ground, a bright one, and as outlines
    f64 = 64 / (5 * px / span)
    x0, y0 = 1626, 30
    for r, (ground, label, sil) in enumerate(((rs.NIGHT, "64 px, dark ground", False), (rs.DAY, "64 px, bright ground", False),
                                              (rs.PAPER, "64 px, outline", True))):
        y = y0 + r * 118
        rs.fill(page, x0, y, 290, 100, ground)
        for c, name in enumerate(("game", "quarter", "wound")):
            shot = rs.shrink(shots[name], f64)
            rs.stand(page, rs.black(shot) if sil else shot, x0 + 6 + c * 94, y + 94, 90)
        text.append((x0, y + 102, 12, label, soft))
    atlas = rs.load(paths["Color"])
    rs.paste(page, rs.shrink(atlas, 260 / SIZE), x0, 400)
    text.append((x0, 666, 12, "the colour map, 1024 px", soft))
    for i, line in enumerate(facts):
        text.append((x0, 700 + i * 22, 13, line, ink))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "rook_model_sheet.png")
    rs.save(rs.shrink(page, 0.5), out / "rook_model_sheet_small.png")


def atlas_check(paths, out):
    """The colour map as it uploads, for the content check: whole, and at 64 px on a dark and a bright ground."""
    atlas = rs.load(paths["Color"])
    atlas[..., 3] = 1.0
    page = rs.canvas(SIZE + 400, SIZE + 40, rs.NIGHT)
    rs.paste(page, atlas, 20, 20)
    small = rs.shrink(atlas, 64 / SIZE)
    rs.fill(page, SIZE + 40, 240, 360, 160, rs.DAY)
    rs.paste(page, small, SIZE + 60, 60)
    rs.paste(page, small, SIZE + 60, 288)
    rs.paste(page, rs.shrink(atlas, 256 / SIZE), SIZE + 60, 460)
    soft = "#9A9CA8"
    text = [(SIZE + 60, 28, 13, "64 px, on dark", soft), (SIZE + 60, 216, 13, "64 px, on bright", soft),
            (SIZE + 60, 428, 13, "256 px", soft)]
    rs.paste(page, rs.text_layer(page.shape[1], page.shape[0], text), 0, 0)
    rs.save(page, out / "rook_atlas_check.png")


def main():
    out = bl.out_dir()
    rs.OUT = out
    scene = bl.reset_scene()
    joints = rs.build(scene, rs.CHOSEN, model=True)
    surfaces()
    groups = take_pieces(joints)
    hidden = total = 0
    for index, piece in enumerate(PIECES):
        h, t = mark_faces(groups[piece], index)
        hidden, total = hidden + h, total + t
        for o in groups[piece]:
            o.data.transform(Matrix.Translation((APART * index, 0, 0)))
    whole = bl.join([o for piece in PIECES for o in groups[piece]], "Rook")
    area, density = unwrap(whole)
    print(f"faces {total}, unseen {hidden}; seen area {area:.1f} sq studs; {density:.0f} px per stud at {SIZE}")
    paths = bake(whole, out)
    made = split(whole)
    recipe = export(made, paths, out, density)
    pts = [v.co for o in made.values() for v in o.data.vertices]
    tall = max(p.z for p in pts)
    wide = max(p.x for p in pts) - min(p.x for p in pts)
    facts = [f"{recipe['tris']} triangles in {len(made)} pieces", f"{tall:.2f} studs tall, {wide:.2f} wide",
             f"one {SIZE} px atlas, {density:.0f} px per stud", "2 extra joints: the piston, the tape ends",
             "maps: colour, roughness, metalness, glow mask"]
    print("; ".join(facts))
    review(joints, made, paths, recipe, out, facts)
    atlas_check(paths, out)


if __name__ == "__main__":
    main()
