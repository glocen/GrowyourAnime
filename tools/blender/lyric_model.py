"""Lyric's model (AR4, delivery 2): her pieces on the R6 rig, one baked texture set, the exports and the review sheet.

blender.exe -b --factory-startup --python tools/blender/lyric_model.py -- <out_dir> [look]

How she sits on R6: a rigid mesh for each of the six parts, carrying the body's own surface, so the rig's blocks are
hidden; three pieces on joints of their own; and three thin edges. The stand is on the Right Arm, its joint where her
fist meets the pole: the clips swing it about her right hand. Each speaker floats on a joint on the Torso, held by
nothing, its rest turn and its scale in the mesh. The edges are research's fix 3 on the sheet: a dark shell a hair
larger than the pale parts (the bob and the boots), turned inside out, so only its far side shows, just past their
outline, and she holds over bright ground. An edge is a piece of its own because it must cast no shadow.

Everything shares one 1024 px atlas: colour with the contact shading baked in, roughness, metalness (the chrome), and
a glow mask. Everything lit (the speakers' rings, the mic's ring, the headset's tip, the meter) sits on the Glow
swatch: one flat block of Storm's pink on both maps. No normal map: the low mesh is the form.

`look` stops before the bake: the model in Workbench on a quick sheet, no GPU turn.

Writes to <out_dir>: Lyric_<Piece>.json, Lyric_<Map>.png, Lyric.recipe.json, lyric_model.blend, lyric_model_sheet.png
and lyric_atlas_check.png. The shapes come from lyric_sheet.build(model=True); the unwrap, the bake and the review's
tools from rook_model.py. The bake is Cycles, under build/locks/blender.lock.
"""
import json
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import lyric_sheet as ls  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402

SIZE = rm.SIZE
APART = rm.APART
JOINTS = {"root": "Torso", "neck": "Head", "rs": "RightArm", "ls": "LeftArm", "rh": "RightLeg", "lh": "LeftLeg",
          "staff": "Staff", "dr": "SpeakerR", "dl": "SpeakerL"}
MOTORS = {"Staff": "RightArm", "SpeakerR": "Torso", "SpeakerL": "Torso"}  # a piece on a joint of its own: its part
EDGES = {"HeadEdge": "Head", "RightLegEdge": "RightLeg", "LeftLegEdge": "LeftLeg"}  # an edge: the piece it wraps
PIECES = [*JOINTS.values(), *EDGES]
FOOT = Vector((1.5, 0.68, 0.0))      # the stand's base at rest: upright, its pole just in front of her hanging fist
GRIP = FOOT + Vector((0, 0, 2.15))   # the stand's joint: level with the middle of that fist


def turned(name):
    """A speaker at rest: its middle, its turn inward, its scale."""
    at, inward = ls.REST[name]
    return Matrix.Translation(at) @ Matrix.Rotation(math.radians(inward), 4, "Z") @ Matrix.Scale(ls.SPEAKER, 4)


RESTS = {"staff": Matrix.Translation(FOOT), "dr": turned("dr"), "dl": turned("dl")}  # in the mesh
PIVOTS = {**rs.PIVOTS, "staff": tuple(GRIP), "dr": ls.REST["dr"][0], "dl": ls.REST["dl"][0]}
# surface: (roughness, metalness). The chrome keeps most of its own colour: full metal goes black wherever the sky is.
SURFACES = {
    "Limelight": (0.78, 0.0), "LimelightDeep": (0.8, 0.0), "Backstage": (0.85, 0.0), "BackstageLift": (0.75, 0.0),
    "Ash": (0.7, 0.0), "Chalk": (0.85, 0.0), "Rose": (0.8, 0.0), "Chrome": (0.3, 0.6), "ChromeDeep": (0.42, 0.55),
    "Skin": (0.65, 0.0), "Ink": (0.5, 0.0), "Glow": (0.4, 0.0),
}
LIT = ("Glow",)
GROUND = "Backstage"  # the colour map's tone past the islands
BEVELS = {"Clip": 0.015, "Clutch": 0.02, "Frame": 0.02, "Handle": 0.015, "HandlePost": 0.012, "Slot": 0.01,
          "Pack": 0.03}
EDGE = 0.035          # studs: how far the dark shell stands out from the pale parts
COLD, HOT = 1.0, 2.5  # the glow's EmissiveStrength: as she stands, and through the note
CROWN = (4.85, 5.22)  # studs: the crown's cooler tone starts at the fringe's highest edge and is whole at the top
SPAN, PX = 10.0, 640


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


def crown():
    """Research's model fix 1: the crown a step cooler than Ash, rising into it over the top of her head, so sun
    doesn't flatten the bob to white. A blend by height, never a seam, which would read as a helmet's rim. Only the
    colour bake reads it, and no Ash but her hair stands that high."""
    m = bpy.data.materials["Ash"]
    nodes, links = m.node_tree.nodes, m.node_tree.links
    height = nodes.new("ShaderNodeSeparateXYZ")
    links.new(nodes.new("ShaderNodeNewGeometry").outputs["Position"], height.inputs["Vector"])
    rise = nodes.new("ShaderNodeMapRange")
    rise.inputs["From Min"].default_value, rise.inputs["From Max"].default_value = CROWN
    links.new(height.outputs["Z"], rise.inputs["Value"])
    tone = bl._mix_colour(nodes, links, rise.outputs["Result"], rs.srgb(ls.PALETTE["Ash"]), rs.srgb(ls.PALETTE["AshCool"]))
    links.new(tone, nodes["Principled BSDF"].inputs["Base Color"])


def take_pieces(joints):
    """The build's objects by piece, finished and standing free in the model's frame: the stand and the speakers
    where they rest."""
    groups = {piece: [o for o in joints[key].children if o.type == "MESH"] for key, piece in JOINTS.items()}
    for key, piece in JOINTS.items():
        for o in groups[piece]:
            o.parent = None
            o.matrix_world = Matrix.Identity(4)
            if key in RESTS:
                o.data.transform(RESTS[key])
            if rm.base(o) in BEVELS:
                bl.bevel(o, BEVELS[rm.base(o)], segments=2)
            bl.smooth_by_angle(o, 32)
    return groups


def edges(obj, surfaces=None):
    """Research's fix 3: every Ash face again, pushed out along its corners' normals, turned inside out, dark, and
    made a piece of its own (the edge of the piece it wraps). With `surfaces`, its UVs go on the Backstage swatch.
    Not the fringe's tips (`bare`): they sit inside her outline, and each boxed in its own dark rim, in a row over her
    eyes, they read as teeth."""
    mesh = obj.data
    names = [m.name for m in mesh.materials]
    pale, dark = names.index("Ash"), names.index("Backstage")
    bm = bmesh.new()
    bm.from_mesh(mesh)
    piece = bm.faces.layers.int["piece"]
    unseen = bm.faces.layers.int["unseen"]
    bare = bm.faces.layers.int["bare"]
    made = bmesh.ops.duplicate(bm, geom=[f for f in bm.faces if f.material_index == pale and not f[bare]])
    faces = [g for g in made["geom"] if isinstance(g, bmesh.types.BMFace)]
    verts = [g for g in made["geom"] if isinstance(g, bmesh.types.BMVert)]
    bm.normal_update()
    to_edge = {PIECES.index(part): PIECES.index(edge) for edge, part in EDGES.items()}
    moves = {}
    for v in verts:
        src = v.link_faces[0][piece]
        if src not in to_edge:
            raise SystemExit(f"an Ash face on {PIECES[src]}, which has no edge piece")
        moves[v] = v.normal * EDGE + Vector((APART * (to_edge[src] - src), 0, 0))
    for v, move in moves.items():
        v.co += move
    for f in faces:
        f[piece] = to_edge[f[piece]]
        f[unseen] = 1
        f.material_index = dark
    bmesh.ops.reverse_faces(bm, faces=faces)
    if surfaces:
        uv = bm.loops.layers.uv.active
        at = ((list(surfaces).index("Backstage") + 0.5) / len(surfaces), rm.STRIP * 0.4)
        for f in faces:
            for loop in f.loops:
                loop[uv].uv = at
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    return len(faces)


def joint_of(piece):
    return next(k for k, p in JOINTS.items() if p == EDGES.get(piece, piece))


def mount(joints, made):
    """Hangs each piece on its joint, so the sheet's poses move it; an edge on the joint of the piece it wraps."""
    for piece, o in made.items():
        key = joint_of(piece)
        o.parent = joints[key]
        o.matrix_parent_inverse = RESTS[key].inverted() if key in RESTS else Matrix.Translation(-Vector(PIVOTS[key]))
        if piece in EDGES:
            o.visible_shadow = False  # as the recipe asks of the engine: an edge casts no shadow


def glowing(made):
    """The pieces with lit faces."""
    out = []
    for piece, o in made.items():
        lit = {i for i, m in enumerate(o.data.materials) if m and m.name in LIT}
        if any(p.material_index in lit for p in o.data.polygons):
            out.append(o.name)
    return out


# --- the hand-off -----------------------------------------------------------------------------------------------

def export(made, paths, out, density, lit):
    """Each piece as JSON for Studio, and the recipe's facts. Points are Roblox's: studs, Y up, the model standing
    on y = 0 and facing -Z, its HumanoidRootPart at (0, 3, 0)."""
    pieces, total = [], 0
    for piece, o in made.items():
        tris = bl.export_mesh_json(o, out / f"{o.name}.json")
        total += tris
        box = [v.co for v in o.data.vertices]
        size = [round(max(c[i] for c in box) - min(c[i] for c in box), 3) for i in (0, 2, 1)]
        part = MOTORS.get(piece) or EDGES.get(piece) or piece
        entry = {"name": o.name, "mesh": f"{o.name}.json", "on": rm.R6[part],
                 "centre": json.loads((out / f"{o.name}.json").read_text())["c"], "size": size, "tris": tris}
        if piece in MOTORS:
            entry["motor"] = piece
            entry["pivot"] = rm.roblox(PIVOTS[joint_of(piece)])
        if piece in EDGES:
            entry["edge"] = True
        pieces.append(entry)
        print(f"{o.name}: {tris} tris, {size} studs")
    ring = Vector((0, 0.47, -0.12))  # a speaker's cone face, where it's drawn
    recipe = {
        "name": "Lyric",
        "frame": "Roblox studs: Y up, the model on y = 0 facing -Z, HumanoidRootPart at (0, 3, 0)",
        "rig": "R6. Every piece carries the body's own surface: the six rig parts are hidden (Transparency 1), and "
               "the Head's face decal is removed. Her face is on the Head piece.",
        "maps": {kind: path.name for kind, path in paths.items()},
        "texels_per_stud": round(density),
        # White: Roblox draws (mask x strength x tint + light) x colour map, and the colour map under every lit face
        # is already Storm's pink. Tinted pink as well, it would come out a deeper, redder pink.
        "emissive": {"tint": "#FFFFFF", "cold": COLD, "hot": HOT, "pieces": lit,
                     "note": "The mask covers the speakers' rings front and back, the mic's ring, the headset's tip "
                             "and the meter on her back, and nothing else. They burn at cold as she stands; the "
                             "speakers and the stand go to hot through the note. The face, the eyes and the rose "
                             "layer of her hair take no glow, ever. The tint is white because Roblox multiplies the "
                             "glow by the colour map, which already holds the pink."},
        "pieces": pieces,
        "motors": {
            "Staff": {"note": "The mic stand, on the Right Arm. Its pivot is where her fist meets the pole: the clips "
                              "swing the stand about her hand and never slide the hand along it (R6 has no elbow). At "
                              "rest it stands upright on its base, the pole just in front of her hanging fist."},
            "SpeakerR": {"note": "Floats at her right shoulder, held by nothing: a joint of its own on the Torso, its "
                                 "pivot at its middle, its rest turn and its 0.9 scale in the mesh. The clips move "
                                 "and turn it; the note throws both ahead to the wave's edges. Whether it rides on "
                                 "her rig or is a part of the builder's that follows her is the builder's call."},
            "SpeakerL": {"note": "The same, at her left shoulder."}},
        "edges": {"pieces": [made[e].name for e in EDGES], "width": EDGE,
                  "note": "Research's fix 3: dark shells 0.035 studs outside the pale parts (the bob and the boots), "
                          "turned inside out, so only their far side shows, just past the outline, and she holds "
                          "over bright ground. Each is welded to its part and takes the same surface (it sits on "
                          "the Backstage swatch). CastShadow off, or it shades the pale part it wraps; DoubleSided "
                          "off (the default), or it covers it."},
        "points": [{"name": "Mic", "on": made["Staff"].name, "at": rm.roblox(FOOT + ls.MIC),
                    "note": "the mic's head: where the note starts"},
                   {"name": "RingR", "on": made["SpeakerR"].name, "at": rm.roblox(RESTS["dr"] @ ring),
                    "note": "the right speaker's cone: where the wave leaves it"},
                   {"name": "RingL", "on": made["SpeakerL"].name, "at": rm.roblox(RESTS["dl"] @ ring),
                    "note": "the left speaker's cone"},
                   {"name": "Chest", "on": "Torso", "at": rm.roblox((0, 0.6, 3.2)), "note": "where a hit lands"}],
        "tris": total,
    }
    (out / "Lyric.recipe.json").write_text(json.dumps(recipe, indent=1))
    return recipe


# --- the review -------------------------------------------------------------------------------------------------

MID, FAR = (0.2, 0.2, 3.3), ls.FAR
FACE = (172, 2)       # level with her eyes
BOB = (22, 10)        # the back of her head, a little from her right: the locks
HEAD = (0, 0, 4.6)


def lighting(scene, azimuth, dusk):
    """Lantern Row's dusk, or a plain day: the sun over the camera's left shoulder either way."""
    rm.sun_for(scene, azimuth)
    sun = bpy.data.objects["Sun"].data
    background = scene.world.node_tree.nodes["Background"]
    if dusk:
        sun.energy, sun.color = 1.9, (0.72, 0.78, 1.0)
        background.inputs["Color"].default_value = (0.2, 0.16, 0.4, 1)
        background.inputs["Strength"].default_value = 0.8
    else:
        sun.energy, sun.color = 3.2, (1.0, 1.0, 1.0)


def shooter(joints, out, shots, dress=None):
    scene = bpy.context.scene

    def take(name, pose, view, at=MID, across=SPAN, dusk=False, clay=False, size=PX):
        rm.rest(joints)
        ls.POSES[pose](joints)
        if dress:
            dress(pose)
        if clay:
            rs.workbench(scene, size, size)
            scene.display.shading.show_backface_culling = True
        else:
            rm.eevee(scene, size, size)
            lighting(scene, view[0], dusk)
        path = out / f"_{name}.png"
        shots[name] = rs.shoot(scene, path, view[0], view[1], at, across)
        path.unlink()
    return take


def review(joints, made, paths, out, facts):
    storm = ls.PALETTE["Storm"]
    cold, hot = rm.baked("Lyric_Cold", paths, 1.0, storm), rm.baked("Lyric_Hot", paths, 2.2, storm)  # the preview's
    for m in (cold, hot):
        m.use_backface_culling = True  # as Roblox draws a MeshPart: one-sided, which is what the edges rely on
    for o in made.values():
        bl.assign_only(o, cold)
    bl.save_blend(out / "lyric_model.blend")  # the pieces standing free in the model's frame, for the clips' rig
    mount(joints, made)

    def dress(pose):
        for piece in ("Staff", "SpeakerR", "SpeakerL"):
            bl.assign_only(made[piece], hot if pose == "note" else cold)

    shots = {}
    take = shooter(joints, out, shots, dress)
    take("front", "square", (180, 4))
    take("back", "square", (0, 4))
    take("side", "square", (90, 4))
    take("quarter", "idle", ls.FRONT)
    take("game", "idle", ls.GAME)
    take("clay", "idle", ls.FRONT, clay=True)
    take("met", "note", ls.MET, at=FAR, across=11.5)
    take("notegame", "note", ls.GAME, at=FAR, across=11.5)
    take("face", "idle", FACE, at=HEAD, across=3.0, size=520)
    take("facedusk", "idle", FACE, at=HEAD, across=3.0, size=520, dusk=True)
    take("bob", "square", BOB, at=(0, 0, 4.55), across=3.0, size=520)
    take("speaker", "square", (20, 8), at=ls.REST["dr"][0], across=2.4, size=520)
    take("quarterdusk", "idle", ls.FRONT, dusk=True)
    take("gamedusk", "idle", ls.GAME, dusk=True)
    take("notedusk", "note", ls.GAME, at=FAR, dusk=True)
    take("notesmall", "note", ls.GAME, at=FAR)

    W, H = 1920, 1060
    ink, soft = "#1E1B22", "#6A6670"
    page = rs.canvas(W, H, rs.PAPER)
    text = [(30, 24, 30, "LYRIC, the model on R6", ink),
            (30, 62, 15, "AR4, delivery 2. Lit as the baked maps draw, the sun over the camera's left shoulder, one-sided as Roblox draws a MeshPart. No bloom: the game's, if any, is the builder's.", soft)]
    k = 0.66
    for i, (name, label) in enumerate((("front", "front"), ("back", "back"), ("side", "her right side"),
                                       ("quarter", "three-quarter, how she stands"), ("game", "the player's camera"))):
        x = 10 + i * 322
        rs.stand(page, rs.shrink(shots[name], k), x, 520, 322)
        text.append((x + 20, 530, 14, label, soft))
    row = (("met", "the note, from the target's side, lit hot", 0.6, 10, 400),
           ("notegame", "the same, the player's camera", 0.6, 410, 330), ("clay", "the form alone", 0.5, 740, 240))
    for name, label, kk, x, width in row:
        rs.stand(page, rs.shrink(shots[name], kk), x, 1010, width)
        text.append((x + 20, 1020, 14, label, soft))
    for i, (name, label, y, ground) in enumerate((("bob", "the back of the bob: the locks", 560, None),
                                                  ("speaker", "a speaker from behind", 560, None),
                                                  ("face", "the face, by day", 800, None),
                                                  ("facedusk", "the same, at dusk", 800, ls.DUSK))):
        x = 990 + (i % 2) * 220
        if ground is not None:
            rs.fill(page, x, y, 212, 212, ground)
        rs.paste(page, rs.shrink(shots[name], 212 / 520), x, y)
        text.append((x + 4, y + 220, 14, label, soft))
    # the 64 px read: a 5 stud body 64 px tall, over a dark ground, Lantern Row's dusk, a bright one, and as outlines:
    # how she stands from the player's camera, the three-quarter, and the note, which is as wide as its cone
    f64 = 64 / (5 * PX / SPAN)
    grounds = ((rs.NIGHT, "64 px, dark ground", ("game", "quarter", "notesmall"), False, "#9A9CA8"),
               (ls.DUSK, "64 px, Lantern Row's dusk, lit as dusk", ("gamedusk", "quarterdusk", "notedusk"), False, "#B8AECB"),
               (rs.DAY, "64 px, bright ground", ("game", "quarter", "notesmall"), False, soft),
               (rs.PAPER, "64 px, outline", ("game", "quarter", "notesmall"), True, soft))
    for r, (ground, label, names, sil, tone) in enumerate(grounds):
        x, y = 20 + (r % 2) * 480, 556 + (r // 2) * 108
        rs.fill(page, x, y, 470, 104, ground)
        for name, cx, width in zip(names, (0, 130, 270), (130, 140, 200)):
            shot = rs.shrink(shots[name], f64)
            rs.stand(page, rs.black(shot) if sil else shot, x + cx, y + 100, width)
        text.append((x + 6, y + 5, 12, label, tone))
    x0 = 1626
    for i, (kind, label) in enumerate((("Color", "the colour map, 1024 px"), ("Emissive", "the glow mask"))):
        atlas = rs.load(paths[kind])
        atlas[..., 3] = 1.0
        rs.paste(page, rs.shrink(atlas, 140 / SIZE), x0 + i * 150, 40)
        text.append((x0 + i * 150, 186, 12, label, soft))
    for i, line in enumerate(facts):
        text.append((x0, 222 + i * 21, 12, line, ink))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "lyric_model_sheet.png")
    rs.save(rs.shrink(page, 0.5), out / "lyric_model_sheet_small.png")


def look(joints, made, out):
    """The model before the bake, in Workbench with its own colours: is it right, before the GPU's turn?"""
    mount(joints, made)
    shots = {}
    take = shooter(joints, out, shots)
    views = (("back", "square", (0, 4), MID, SPAN), ("game", "idle", ls.GAME, MID, SPAN),
             ("front", "square", (180, 4), MID, SPAN), ("met", "note", ls.MET, FAR, 11.5),
             ("bob", "square", BOB, (0, 0, 4.55), 3.0), ("bobgame", "idle", ls.GAME, (0.1, 0, 4.5), 3.0),
             ("face", "idle", FACE, HEAD, 3.0))
    for name, pose, view, at, across in views:
        take(name, pose, view, at=at, across=across, clay=True)
    W, H = 2100, 760
    page = rs.canvas(W, H, rs.PAPER)
    for i, name in enumerate(("back", "game", "front", "met")):
        rs.stand(page, rs.shrink(shots[name], 0.6), 10 + i * 400, 400, 400)
    for i, name in enumerate(("bob", "bobgame", "face")):
        rs.paste(page, rs.shrink(shots[name], 340 / PX), 10 + i * 350, 410)
    small = 64 / (5 * PX / SPAN)
    rs.fill(page, 1100, 420, 400, 110, rs.DAY)
    rs.fill(page, 1100, 540, 400, 110, ls.DUSK)
    for c, name in enumerate(("game", "back", "front", "met")):
        for y in (420, 540):
            rs.stand(page, rs.shrink(shots[name], small * (SPAN / 11.5 if name == "met" else 1)), 1102 + c * 98, y + 106, 96)
    rs.save(page, out / "lyric_model_look.png")


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
    rs.save(page, out / "lyric_atlas_check.png")


def main():
    out = bl.out_dir()
    looking = "look" in sys.argv[sys.argv.index("--") + 2:]
    rs.OUT = ls.OUT = out
    scene = bl.reset_scene()
    joints = ls.build(scene, model=True)
    surfaces()
    crown()
    groups = take_pieces(joints)
    hidden = total = 0
    for index, piece in enumerate(JOINTS.values()):
        h, t = rm.mark_faces(groups[piece], index)
        hidden, total = hidden + h, total + t
        for o in groups[piece]:
            # everything lit takes its swatch: one flat block on both maps. So does everything rose (the hair's under-
            # layer, the speakers' feet): unwrapped, its islands were round and pointed drops shaded to deep magenta on
            # the colour map, and the content check blocked one (AR4, section 5). Rose stays straight-edged or flat.
            if o.data.materials[0].name in (*LIT, "Rose"):
                o.data.attributes["unseen"].data.foreach_set("value", [1] * len(o.data.polygons))
            bare = o.data.attributes.new("bare", "INT", "FACE")  # no dark edge: the fringe's tips
            bare.data.foreach_set("value", [int(rm.base(o) == "Fringe")] * len(o.data.polygons))
            o.data.transform(Matrix.Translation((APART * index, 0, 0)))
    whole = bl.join([o for piece in JOINTS.values() for o in groups[piece]], "Lyric")
    if looking:
        print(f"edge faces {edges(whole)}")
        made = rm.split(whole, PIECES, "Lyric")
        print(f"tris {sum(len(p.vertices) - 2 for o in made.values() for p in o.data.polygons)}")
        look(joints, made, out)
        return
    area, density = rm.unwrap(whole, SURFACES, LIT)
    print(f"faces {total}, unseen {hidden}; seen area {area:.1f} sq studs; {density:.0f} px per stud at {SIZE}")
    paths = rm.bake(whole, out, "Lyric", SURFACES, ls.PALETTE, GROUND, LIT, {"Glow": "Storm"}, "lyric_model.py", LIT)
    print(f"edge faces {edges(whole, SURFACES)}")
    made = rm.split(whole, PIECES, "Lyric")
    lit = glowing(made)
    recipe = export(made, paths, out, density, lit)
    body = [v.co for piece, o in made.items() if piece in JOINTS.values() and piece not in MOTORS for v in o.data.vertices]
    tall = max(p.z for p in body)
    wide = max(p.x for p in body) - min(p.x for p in body)
    facts = [f"{recipe['tris']} triangles in {len(made)} pieces", f"{tall:.2f} studs to the crown, {wide:.2f} wide",
             f"the stand {ls.STAFF} long, the speakers 0.9 by 1.17",
             f"one {SIZE} px atlas, {density:.0f} px per stud", "3 extra joints: the stand, two speakers",
             "3 edges, {:.3f} studs, no shadow".format(EDGE), "maps: colour, roughness, metalness,",
             "and a glow mask on the Glow swatch alone"]
    print("; ".join(facts))
    review(joints, made, paths, out, facts)
    atlas_check(paths, out)


if __name__ == "__main__":
    main()
