"""Pip's model (AR4, delivery 2): his pieces on the R6 rig, one baked texture set, the exports and the review sheet.

blender.exe -b --factory-startup --python tools/blender/pip_model.py -- <out_dir>

How he sits on R6: a rigid mesh for each of the six parts, which carries the body's own surface, so the rig's blocks
are hidden; and two pieces on joints of their own. The hat turns on the head: it lags every move and lifts on the send.
The lantern floats beside his right shoulder, held by nothing: its joint is on the torso, and the clips move it.
Everything shares one 1024 px atlas: colour with the contact shading baked in, roughness, metalness (the brass), and a
glow mask over the lantern's flame alone, which sits on its swatch: one flat block on both maps. No normal map: the
low mesh is the form.

The hat's rest tilt is in its mesh, so he's himself with no clip playing. The face is on the Head piece: large dark
eyes with a catchlight each, never lit.

Writes to <out_dir>: Pip_<Piece>.json (blcommon.export_mesh_json), Pip_<Map>.png, Pip.recipe.json, pip_model.blend,
pip_model_sheet.png and pip_atlas_check.png. The shapes come from pip_sheet.build(model=True), the unwrap, the bake
and the review's tools from rook_model.py. The bake is Cycles, under build/locks/blender.lock.
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import pip_sheet as ps  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_model as sm  # noqa: E402

SIZE = rm.SIZE
APART = rm.APART
JOINTS = {"root": "Torso", "neck": "Head", "rs": "RightArm", "ls": "LeftArm", "rh": "RightLeg", "lh": "LeftLeg",
          "hat": "Hat", "lamp": "Lamp"}
MOTORS = {"Hat": "Head", "Lamp": "Torso"}  # the piece on a joint of its own: the part that joint is on
PIECES = list(JOINTS.values())
PIVOTS = {**ps.PIVOTS, "lamp": ps.LAMP}
REST = Quaternion((1, 0, 0), math.radians(5)) @ Quaternion((0, 1, 0), math.radians(-4))  # the hat's tilt, in its mesh
# surface: (roughness, metalness). The brass keeps most of its own colour: full metal goes black wherever the sky is.
SURFACES = {
    "Inkwell": (0.9, 0.0), "InkwellDeep": (0.92, 0.0), "Chalk": (0.88, 0.0), "ChalkShade": (0.88, 0.0),
    "Brass": (0.36, 0.5), "BrassDeep": (0.45, 0.5), "Leather": (0.7, 0.0), "LeatherLight": (0.7, 0.0),
    "Chestnut": (0.6, 0.0), "Skin": (0.65, 0.0), "Ink": (0.5, 0.0), "Slate": (0.85, 0.0), "Glow": (0.4, 0.0),
}
LIT = ("Glow",)
GROUND = "Inkwell"  # the colour map's tone past the islands
BEVELS = {"Toggle": 0.02, "BookBoard": 0.02, "BookCorner": 0.012, "BookClasp": 0.02, "BookSpine": 0.02, "Bead": 0.04,
          "Tassel": 0.025, "Strap": 0.012}
COLD, HOT = 1.2, 3.0  # the flame's EmissiveStrength: as it floats, and through the send
STRIDE = 25           # degrees each way: a walk's widest that the robe's hem holds


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
    """The build's objects by piece, finished and standing free in the model's frame, the hat with its tilt."""
    tilt = Matrix.Translation(Vector(ps.HAT)) @ REST.to_matrix().to_4x4() @ Matrix.Translation(-Vector(ps.HAT))
    groups = {piece: [o for o in joints[key].children if o.type == "MESH"] for key, piece in JOINTS.items()}
    for piece, objs in groups.items():
        for o in objs:
            o.parent = None
            o.matrix_world = Matrix.Identity(4)
            if piece == "Hat":
                o.data.transform(tilt)
            if rm.base(o) in BEVELS:
                bl.bevel(o, BEVELS[rm.base(o)], segments=2)
            bl.smooth_by_angle(o, 32)
    return groups


def draw_cloth(obj, paths):
    """The folds, drawn into the colour map in value alone (research's fix 1): the robe's, which its shape has too, the
    cloth stacked over its hem, and three down each sleeve. Each texel is drawn from where it is on its piece."""
    used = [slot.material for slot in obj.material_slots if slot.material]
    extra = {}
    held = rm.lock("pip_model.py")
    try:
        for name, real, glowing in (("Cloth", False, bl._Glowing(used, ("Inkwell",))), ("Probe", True, sm._Probing(used))):
            extra[name] = bpy.data.images.new(f"Pip_{name}_", SIZE, SIZE, alpha=False, float_buffer=real)
            extra[name].colorspace_settings.name = "Non-Color"
            for m in used:
                m.node_tree.nodes.active.image = extra[name]
            with glowing:
                bpy.ops.object.bake(type="EMIT", use_clear=True)
    finally:
        held.unlink(missing_ok=True)
    probe = rm.pixels(extra["Probe"])
    x, y, z = probe[..., 0] * 100 - 5, probe[..., 1] * 100 - 5, probe[..., 2] * 10 - 1
    piece = np.rint(x / APART).astype(np.int32)
    cloth = rm.pixels(extra["Cloth"])[..., 0] > 0.5
    value = np.ones(x.shape, dtype=np.float32)
    robe = cloth & (piece == PIECES.index("Torso"))
    a = np.degrees(np.arctan2(y, x))
    value = np.where(robe, ps.cloth_value(a, z) + ps.bunch(a, z), value)
    for name, side in (("RightArm", 1.0), ("LeftArm", -1.0)):
        index = PIECES.index(name)
        a = np.degrees(np.arctan2(y, (x - APART * index - side * 1.55) * side))
        value = np.where(cloth & (piece == index) & (z < 3.95), ps.cloth_value(a, z, ps.SLEEVE_FOLDS), value)
    image = bpy.data.images["Pip_Color"]
    colour = rm.pixels(image)
    colour[..., :3] = (colour[..., :3] * np.clip(value, 0.7, 1.3)[..., None]).clip(0, 1)
    image.pixels.foreach_set(colour.ravel())
    image.save()


# --- the hand-off -----------------------------------------------------------------------------------------------

def export(made, paths, out, density):
    """Each piece as JSON for Studio, and the recipe's facts. Points are Roblox's: studs, Y up, the model standing
    on y = 0 and facing -Z, its HumanoidRootPart at (0, 3, 0)."""
    pieces, total = [], 0
    for piece, o in made.items():
        tris = bl.export_mesh_json(o, out / f"{o.name}.json")
        total += tris
        box = [v.co for v in o.data.vertices]
        size = [round(max(c[i] for c in box) - min(c[i] for c in box), 3) for i in (0, 2, 1)]
        entry = {"name": o.name, "mesh": f"{o.name}.json", "on": rm.R6[MOTORS.get(piece, piece)],
                 "centre": json.loads((out / f"{o.name}.json").read_text())["c"], "size": size, "tris": tris}
        if piece in MOTORS:
            entry["motor"] = piece
            entry["pivot"] = rm.roblox(PIVOTS[next(k for k, p in JOINTS.items() if p == piece)])
        pieces.append(entry)
        print(f"{o.name}: {tris} tris, {size} studs")
    recipe = {
        "name": "Pip",
        "frame": "Roblox studs: Y up, the model on y = 0 facing -Z, HumanoidRootPart at (0, 3, 0)",
        "rig": "R6. Every piece carries the body's own surface: the six rig parts are hidden (Transparency 1), and "
               "the Head's face decal is removed. His face is on the Head piece.",
        "maps": {kind: path.name for kind, path in paths.items()},
        "texels_per_stud": round(density),
        # White: Roblox draws (mask x strength x tint + light) x colour map, and the colour map under the flame is
        # the flame's own orange. Tinted orange as well, it would come out red.
        "emissive": {"tint": "#FFFFFF", "cold": COLD, "hot": HOT, "pieces": ["Pip_Lamp"],
                     "note": "The mask covers the lantern's flame and nothing else. It burns at cold as it floats and "
                             "goes to hot through Lantern Burst's send. The face and the eyes take no glow, ever. "
                             "The tint is white because Roblox multiplies the glow by the colour map, which already "
                             "holds the flame's orange: an orange tint over it turns the flame red."},
        "pieces": pieces,
        "motors": {"Hat": {"note": "Turns about its pivot on the head: it lags every move and lifts on the send. Its "
                                   "rest tilt is in the mesh. CastShadow off on this piece, or the brim puts his face "
                                   "in the dark."},
                   "Lamp": {"note": "Floats beside his right shoulder, held by nothing. Its joint is on the Torso, and "
                                    "the clips move and turn it; Lantern Burst sends it. CastShadow off: it's a light. A "
                                    "light in the tint around it is the builder's call, tuned in the engine."}},
        "points": [{"name": "Lantern", "on": "Pip_Lamp", "at": rm.roblox(ps.LAMP), "note": "the flame's middle: where the burst's light starts"},
                   {"name": "Sleeve", "on": "Right Arm", "at": rm.roblox((1.6, 0.0, 1.5)), "note": "the right cuff's opening: the send's line starts here"},
                   {"name": "Chest", "on": "Torso", "at": rm.roblox((0, 0.6, 3.2)), "note": "where a hit lands"}],
        "stride": {"degrees": STRIDE, "note": "each leg's widest swing that stays inside the robe's hem"},
        "tris": total,
    }
    (out / "Pip.recipe.json").write_text(json.dumps(recipe, indent=1))
    return recipe


# --- the review -------------------------------------------------------------------------------------------------

def pose_stride(joints):
    """A walk's widest: the legs as far as the hem holds them, the sleeves hanging."""
    swing = math.tan(math.radians(STRIDE))
    rs.aim(joints["rs"], Quaternion(), (0.14, -0.2, -1.0))
    rs.aim(joints["ls"], Quaternion(), (-0.14, 0.2, -1.0))
    rs.aim(joints["rh"], Quaternion(), (0.0, swing, -1.0))
    rs.aim(joints["lh"], Quaternion(), (0.0, -swing, -1.0))
    ps.settle(joints, ps.LAMP)


POSES = {**ps.POSES, "stride": pose_stride}
MID, FAR = (0.3, 0, 3.75), (0.4, 2.6, 3.6)
BEHIND, LOW = (22, -4), (158, -6)  # from low behind and low in front: what a stride shows of the hem
FACE = (172, -4)                   # level with his eyes, a little under the brim


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


def review(joints, made, paths, recipe, out, facts):
    scene = bpy.context.scene
    flame = ps.PALETTE["Flame"]
    cold, hot = rm.baked("Pip_Cold", paths, 1.0, flame), rm.baked("Pip_Hot", paths, 2.2, flame)  # the preview's own strengths
    for o in made.values():
        bl.assign_only(o, cold)
    bl.save_blend(out / "pip_model.blend")  # the pieces standing free in the model's frame, for the clips' rig
    for piece, o in made.items():
        key = next(k for k, p in JOINTS.items() if p == piece)
        o.parent = joints[key]
        o.matrix_parent_inverse = Matrix.Translation(-Vector(PIVOTS[key]))
    made["Hat"].visible_shadow = False  # as the recipe asks of the engine: the brim doesn't put his face in the dark
    made["Lamp"].visible_shadow = False  # nor the lantern a blot on his sleeve: it's a light
    span, px = 9.6, 640
    shots = {}

    def take(name, pose, view, at=MID, across=span, dusk=False, clay=False, size=px):
        rm.rest(joints)
        joints["hat"].rotation_quaternion = REST
        POSES[pose](joints)
        joints["hat"].rotation_quaternion = joints["hat"].rotation_quaternion @ REST.inverted()  # the tilt is in the mesh
        bl.assign_only(made["Lamp"], hot if pose == "send" else cold)
        if clay:
            rs.workbench(scene, size, size)
        else:
            rm.eevee(scene, size, size)
            lighting(scene, view[0], dusk)
        path = out / f"_{name}.png"
        shots[name] = rs.shoot(scene, path, view[0], view[1], at, across)
        path.unlink()

    take("front", "square", (180, 4))
    take("back", "square", (0, 4))
    take("side", "square", (90, 4))
    take("quarter", "idle", ps.FRONT)
    take("game", "idle", ps.GAME)
    take("clay", "idle", ps.FRONT, clay=True)
    take("flinch", "send", ps.FLINCH, at=FAR, across=11.5)
    take("sent", "send", ps.GAME, at=FAR, across=11.5)
    take("face", "idle", FACE, at=(0, 0, 4.6), across=3.0, size=520)
    take("facedusk", "idle", FACE, at=(0, 0, 4.6), across=3.0, size=520, dusk=True)
    take("stride", "stride", BEHIND)
    take("stridelow", "stride", LOW)
    take("quarterdusk", "idle", ps.FRONT, dusk=True)
    take("gamedusk", "idle", ps.GAME, dusk=True)
    take("sentdusk", "send", ps.GAME, at=FAR, across=span, dusk=True)
    take("sentsmall", "send", ps.GAME, at=FAR, across=span)

    W, H = 1920, 1060
    ink, soft = "#1E1B22", "#6A6670"
    page = rs.canvas(W, H, rs.PAPER)
    text = [(30, 24, 30, "PIP, the model on R6", ink),
            (30, 62, 15, "AR4, delivery 2. Lit as the baked maps draw, the sun over the camera's left shoulder. No bloom: the game's, if any, is the builder's.", soft)]
    k = 0.66
    for i, (name, label) in enumerate((("front", "front"), ("back", "back"), ("side", "his right side"),
                                       ("quarter", "three-quarter, how he stands"), ("game", "the player's camera"))):
        x = 10 + i * 322
        rs.stand(page, rs.shrink(shots[name], k), x, 520, 322)
        text.append((x + 20, 530, 14, label, soft))
    row = (("flinch", "Lantern Burst's send, the flame hot", 0.6, 10, 400), ("sent", "the same, the player's camera", 0.6, 410, 330),
           ("clay", "the form alone", 0.5, 740, 240))
    for name, label, kk, x, width in row:
        rs.stand(page, rs.shrink(shots[name], kk), x, 1010, width)
        text.append((x + 20, 1020, 14, label, soft))
    for i, (name, label, ground) in enumerate((("face", "the face under the brim, by day", None), ("facedusk", "the same, at dusk", ps.DUSK))):
        x = 990 + i * 220
        if ground is not None:
            rs.fill(page, x, 800, 212, 212, ground)
        rs.paste(page, rs.shrink(shots[name], 212 / 520), x, 800)
        text.append((x + 4, 1020, 14, label, soft))
    for i, (name, label) in enumerate((("stride", "a stride, from low behind"), ("stridelow", "and low in front"))):
        x = 990 + i * 220
        rs.stand(page, rs.shrink(shots[name], 0.36), x, 770, 212)
        text.append((x + 4, 776, 14, label, soft))
    # the 64 px read: a 5 stud body 64 px tall, over a dark ground, Lantern Row's dusk, a bright one, and as outlines
    f64 = 64 / (5 * px / span)
    x0, y0 = 1626, 24
    grounds = ((rs.NIGHT, "64 px, dark ground", ("game", "quarter", "sentsmall"), False),
               (ps.DUSK, "64 px, Lantern Row's dusk, lit as dusk", ("gamedusk", "quarterdusk", "sentdusk"), False),
               (rs.DAY, "64 px, bright ground", ("game", "quarter", "sentsmall"), False),
               (rs.PAPER, "64 px, outline", ("game", "quarter", "sentsmall"), True))
    for r, (ground, label, names, sil) in enumerate(grounds):
        y = y0 + r * 126
        rs.fill(page, x0, y, 290, 106, ground)
        for c, name in enumerate(names):
            shot = rs.shrink(shots[name], f64)
            rs.stand(page, rs.black(shot) if sil else shot, x0 + 2 + c * 96, y + 102, 94)
        text.append((x0, y + 108, 12, label, soft))
    for i, (kind, label) in enumerate((("Color", "the colour map, 1024 px"), ("Emissive", "the glow mask"))):
        atlas = rs.load(paths[kind])
        atlas[..., 3] = 1.0
        rs.paste(page, rs.shrink(atlas, 140 / SIZE), x0 + i * 150, 540)
        text.append((x0 + i * 150, 684, 12, label, soft))
    for i, line in enumerate(facts):
        text.append((x0, 716 + i * 21, 12, line, ink))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "pip_model_sheet.png")
    rs.save(rs.shrink(page, 0.5), out / "pip_model_sheet_small.png")


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
    rs.save(page, out / "pip_atlas_check.png")


def main():
    out = bl.out_dir()
    rs.OUT = ps.OUT = out
    scene = bl.reset_scene()
    joints = ps.build(scene, model=True)
    surfaces()
    groups = take_pieces(joints)
    hidden = total = 0
    for index, piece in enumerate(PIECES):
        h, t = rm.mark_faces(groups[piece], index)
        hidden, total = hidden + h, total + t
        for o in groups[piece]:
            if rm.base(o) == "LampFlame":  # the flame takes its swatch, one flat block on both maps: unwrapped, its
                # islands are drops in the flame's colour on the colour map (the content check, 2026-11-12)
                o.data.attributes["unseen"].data.foreach_set("value", [1] * len(o.data.polygons))
        for o in groups[piece]:
            o.data.transform(Matrix.Translation((APART * index, 0, 0)))
    whole = bl.join([o for piece in PIECES for o in groups[piece]], "Pip")
    area, density = rm.unwrap(whole, SURFACES, LIT)
    print(f"faces {total}, unseen {hidden}; seen area {area:.1f} sq studs; {density:.0f} px per stud at {SIZE}")
    paths = rm.bake(whole, out, "Pip", SURFACES, ps.PALETTE, GROUND, LIT, {"Glow": "Flame"}, "pip_model.py", LIT)
    draw_cloth(whole, paths)
    made = rm.split(whole, PIECES, "Pip")
    recipe = export(made, paths, out, density)
    body = [v.co for piece, o in made.items() if piece != "Lamp" for v in o.data.vertices]
    tall = max(p.z for p in body)
    wide = max(p.x for p in body) - min(p.x for p in body)
    facts = [f"{recipe['tris']} triangles in {len(made)} pieces", f"{tall:.2f} studs to the hat's top, {wide:.2f} wide",
             f"one {SIZE} px atlas, {density:.0f} px per stud", "2 extra joints: the hat, the lantern",
             "maps: colour, roughness, metalness,", "and a glow mask on the flame alone",
             f"a stride holds to {STRIDE} degrees each way"]
    print("; ".join(facts))
    review(joints, made, paths, recipe, out, facts)
    atlas_check(paths, out)


if __name__ == "__main__":
    main()
