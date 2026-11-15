"""Watt's model (AR11, delivery 2, take A): his pieces on the R6 rig, one baked texture set, the exports and a review.

blender.exe -b --factory-startup --python tools/blender/watt_model.py -- <out_dir> [dry] [cpu]

`dry` stops before the bake, with the pieces counted and unwrapped: a light run. `cpu` bakes on the processor: slower,
and it leaves out the GPU's own memory, for when the PC is short of it.

How he sits on R6: as Pip and Kirra do. A rigid mesh for each of the six parts carries the body's own surface, so the
rig's blocks are hidden. What watt_sheet.py paints a layer off a block is cut into the block's face here (its
`flatten`): one flat surface, the shapes' edges edges of the mesh. The spear is a seventh piece on a joint of its own
on the Torso, its pivot at the grip. Its mesh lies slung on his back, so with no clip it rides on him; his clips key
it into his fist, planted, which is how he stands.

Everything shares one 1024 px atlas: colour with the contact shading baked in, roughness, metalness (the spear's iron
and steel), and a glow mask over what Storm lights: the hair's pale ends (the Head) and the three ceramic discs (the
Spear). Each lit surface sits on its swatch, one flat block on every map. No normal map: the low mesh is the form.

Writes to <out_dir>: Watt_<Piece>.json (blcommon.export_mesh_json), Watt_<Map>.png, Watt.recipe.json,
watt_model.blend, watt_model_sheet.png and watt_atlas_check.png. The shapes come from watt_sheet.build(model=True),
the unwrap, the bake and the review's tools from rook_model.py. The bake is Cycles, under build/locks/blender.lock.
"""
import json
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import pip_model as pm  # noqa: E402
import pip_sheet as ps  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402
import watt_sheet as ws  # noqa: E402

SIZE = rm.SIZE
APART = 16.0  # studs between the pieces while they bake: the spear lies 3.4 across
JOINTS = {"root": "Torso", "neck": "Head", "rs": "RightArm", "ls": "LeftArm", "rh": "RightLeg", "lh": "LeftLeg", "spear": "Spear"}
MOTORS = {"Spear": "Torso"}  # the piece on a joint of its own: the part that joint is on
PIECES = list(JOINTS.values())
PALETTE = {**ws.PALETTE, "LitTip": ws.PALETTE["Storm"], "LitDisc": ws.PALETTE["Ceramic"]}
# surface: (roughness, metalness). The metals keep most of their own colour: full metal goes black wherever the sky is.
SURFACES = {
    "Coat": (0.84, 0.0), "CoatShade": (0.86, 0.0), "CoatLight": (0.82, 0.0), "Storm": (0.78, 0.0), "StormDeep": (0.3, 0.0),
    "Shirt": (0.86, 0.0), "ShirtShade": (0.86, 0.0), "Trouser": (0.86, 0.0), "TrouserShade": (0.86, 0.0),
    "Boot": (0.6, 0.0), "Sole": (0.8, 0.0), "Skin": (0.62, 0.0), "SkinShade": (0.66, 0.0), "Hair": (0.55, 0.0),
    "HairLight": (0.5, 0.0), "Ink": (0.5, 0.0), "White": (0.3, 0.0), "Iron": (0.46, 0.5), "Ceramic": (0.3, 0.0),
    "Steel": (0.36, 0.55), "LitTip": (0.5, 0.0), "LitDisc": (0.3, 0.0),
}
LIT = ("LitTip", "LitDisc")
COLD = {"LitTip": "Storm", "LitDisc": "Ceramic"}  # a lit surface's colour with its light out
LOCKS = ("Sweep", "Crown", "Back", "Side", "SideLow", "Nape")  # the hair whose ends are Storm's
GROUND = "Coat"  # the colour map's tone past the islands
BEVELS = {"Boot": 0.03}
STORM = ws.PALETTE["Storm"]
# Each lit piece's EmissiveTint and EmissiveStrength: as he stands, and in Ground Wire's hold. Roblox multiplies the
# glow by the colour map (rm.baked's `through`), so the ends glow in their own Storm and the discs take it from the tint.
GLOW = {"Head": ("#FFFFFF", 0.0, 3.0, "the hair's pale ends"),
        "Spear": (STORM, 0.0, 2.5, "the three ceramic discs")}


# --- the pieces ---------------------------------------------------------------------------------------------

def surfaces():
    for name, (rough, metal) in SURFACES.items():
        m = bpy.data.materials.get(name)
        if m is None:  # a lit surface: its own colour, on a swatch of its own
            m = bpy.data.materials.new(name)
            m.diffuse_color = rs.srgb(PALETTE[name])
        if not (m.node_tree and m.node_tree.nodes.get("Principled BSDF")):
            m.use_nodes = True
        bsdf = m.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = tuple(m.diffuse_color)
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = metal


def tidy(obj):
    """Removes the vertices and edges no face uses: rook_model.split keeps them in every piece, where they'd stretch
    each piece's box back to the Torso's place."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    loose = [v for v in bm.verts if not v.link_faces]
    if loose:
        print(f"tidy: {obj.name}, {len(loose)} loose vertices", flush=True)
        bmesh.ops.delete(bm, geom=loose, context="VERTS")
        bm.to_mesh(obj.data)
    bm.free()


def take_pieces(joints):
    """The build's objects by piece, finished and standing free in the model's frame, the lit surfaces named."""
    groups = {piece: [o for o in joints[key].children if o.type == "MESH"] for key, piece in JOINTS.items()}
    swaps = {"Storm": bpy.data.materials["LitTip"], "Ceramic": bpy.data.materials["LitDisc"]}
    for piece, objs in groups.items():
        for o in objs:
            o.parent = None
            o.matrix_world = Matrix.Identity(4)
            tidy(o)
            if rm.base(o) in LOCKS or rm.base(o) == "Disc":
                for slot in o.material_slots:
                    slot.material = swaps.get(slot.material.name, slot.material)
            if rm.base(o) in BEVELS:
                bl.bevel(o, BEVELS[rm.base(o)], segments=2)
            if rm.base(o) != "Head":  # the head is smooth all over, its face cut into it
                bl.smooth_by_angle(o, 32)
    return groups


# --- the hand-off -----------------------------------------------------------------------------------------------

def export(made, paths, out, density, pivots):
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
            entry["pivot"] = rm.roblox(pivots[next(k for k, p in JOINTS.items() if p == piece)])
        pieces.append(entry)
        print(f"{o.name}: {tris} tris, {size} studs")
    butt, along, grip = ws.slung()
    fist = ws.hand()
    recipe = {
        "name": "Watt",
        "frame": "Roblox studs: Y up, the model on y = 0 facing -Z, HumanoidRootPart at (0, 3, 0)",
        "rig": "R6. Every piece carries the body's own surface: the six rig parts are hidden (Transparency 1), and "
               "the Head's face decal is removed. His face is on the Head piece.",
        "maps": {kind: path.name for kind, path in paths.items()},
        "texels_per_stud": round(density),
        "emissive": {
            "pieces": {f"Watt_{piece}": {"tint": tint, "cold": cold, "hot": hot, "lit": what}
                       for piece, (tint, cold, hot, what) in GLOW.items()},
            "note": "One mask for both pieces; each takes its own EmissiveTint and EmissiveStrength: cold as he "
                    "stands, hot in Ground Wire's hold. Roblox multiplies the glow by the colour map, so the hair's "
                    "ends glow in their own pale pink, and the discs take Storm from their tint. The other five "
                    "pieces take no glow, and his face none, ever. DESIGN: the strengths are the review's, untried "
                    "in Studio. The glow stays at Storm's pale end, never deeper (the content check)."},
        "pieces": pieces,
        "motors": {
            "Spear": {"along": rm.roblox(along),
                      "stood": {"grip": rm.roblox(fist), "along": [0, 1, 0], "right_arm": rm.roblox(ws.HOLD)},
                      "note": "One piece on the Torso, its pivot at the grip's middle. With no turn it lies slung on "
                              "his back, from behind his left calf to over his right shoulder: `along` is the "
                              "shaft's line, from the butt to the blade. `stood` is how he stands, which his idle "
                              "keys: the grip at his right fist, the shaft upright with its butt on y = 0, and his "
                              "Right Arm turned from hanging to point along `right_arm`. In every clip the blade and "
                              "discs stay clear of his head and neck, and the blade goes into the street only."}},
        "points": [
            {"name": "SpearHead", "on": "Watt_Spear", "at": rm.roblox(butt + along * (ws.SPEAR - 1.07)),
             "note": "the middle disc, on the mesh as it lies, slung: where Storm gathers on the weapon"},
            {"name": "Blade", "on": "Watt_Spear", "at": rm.roblox(butt + along * (ws.SPEAR + 0.12)), "note": "the blade's point"},
            {"name": "Butt", "on": "Watt_Spear", "at": rm.roblox(butt), "note": "the blunt cap: where it meets the street, planted, and where Ground Wire's ring starts"},
            {"name": "Grip", "on": "Watt_Spear", "at": rm.roblox(grip), "note": "the grip's middle: the joint's pivot"},
            {"name": "HairEnds", "on": "Head", "at": rm.roblox((0, -1.2, 5.35)), "note": "behind his crown, where the hair's pale ends lift: where static starts"},
            {"name": "Chest", "on": "Torso", "at": rm.roblox((0, 0.52, 3.2)), "note": "where a hit lands"}],
        "tris": total,
    }
    (out / "Watt.recipe.json").write_text(json.dumps(recipe, indent=1))
    return recipe


# --- the review -------------------------------------------------------------------------------------------------

FACE = (168, 4)
HEAD = (0, 0, 4.72)
MID = (0.5, 0.1, 3.7)


def review(joints, made, paths, recipe, out, facts, pivots):
    """One light, the game's own: Lantern Row's dusk (the director, 2026-11-15: no day-and-night checks)."""
    scene = bpy.context.scene
    plain = rm.baked("Watt_Plain", paths, 0.0)
    hot = {piece: rm.baked(f"Watt_{piece}_Hot", paths, strength, tint, through=True) for piece, (tint, _, strength, _) in GLOW.items()}
    for o in made.values():
        bl.assign_only(o, plain)
    bl.save_blend(out / "watt_model.blend")  # the pieces standing free in the model's frame, for the clips' rig
    home = {}
    for piece, o in made.items():
        key = next(k for k, p in JOINTS.items() if p == piece)
        o.parent = joints[key]
        o.matrix_parent_inverse = Matrix.Translation(-Vector(pivots[key]))
        home[key] = joints[key].location.copy()
    span, px = 10.4, 700
    shots = {}

    def take(name, pose, view, at=MID, across=span, clay=False, size=px, bare=False, lit=False):
        for key in JOINTS:
            joints[key].rotation_quaternion = (1, 0, 0, 0)
            joints[key].location = home[key]
        ws.POSES[pose](joints)
        for piece, material in hot.items():
            bl.assign_only(made[piece], material if lit else plain)
        made["Spear"].hide_render = bare
        if clay:
            rs.workbench(scene, size, size)
        else:
            rm.eevee(scene, size, size)
            pm.lighting(scene, view[0], True)
        path = out / f"_{name}.png"
        shots[name] = rs.shoot(scene, path, view[0], view[1], at, across)
        path.unlink()

    take("game", "stood", ws.GAME)
    take("back", "stood", (0, 8))
    take("quarter", "stood", ws.FRONT)
    take("front", "stood", (180, 4))
    take("slung", "slung", ws.GAME)
    take("lit", "stood", ws.GAME, lit=True)
    take("clay", "stood", ws.GAME, clay=True)
    take("face", "stood", FACE, at=HEAD, across=3.2, size=560, bare=True)

    W, H = 1920, 1060
    ink, soft = "#F2EEE6", "#A9A6B8"
    page = rs.canvas(W, H, ps.DUSK)
    text = [(30, 22, 30, "WATT, the model on R6", ink),
            (30, 60, 15, "AR11, take A with research's three fixes. Lit as the baked maps draw, in Lantern Row's dusk. No bloom: the game's, if any, is the builder's.", soft)]
    k = 0.76
    for i, (name, label) in enumerate((("game", "the player's camera, how he stands"), ("back", "his back"),
                                       ("quarter", "three-quarter front"), ("front", "front"),
                                       ("slung", "the spear slung: the mesh at rest"))):
        x = 10 + i * 322
        rs.stand(page, rs.shrink(shots[name], k), x, 530, 322)
        text.append((x + 20, 538, 14, label, soft))
    for name, label, kk, x, width in (("lit", "Ground Wire's glow: the ends, the discs", 0.62, 10, 300), ("clay", "the form alone", 0.62, 310, 300)):
        rs.stand(page, rs.shrink(shots[name], kk), x, 1010, width)
        text.append((x + 20, 1020, 14, label, soft))
    rs.paste(page, rs.shrink(shots["face"], 420 / 560), 640, 580)
    text.append((644, 1020, 14, "his face, close", soft))
    f64 = 64 / (5 * px / span)
    for c, name in enumerate(("game", "quarter", "slung")):
        rs.stand(page, rs.shrink(shots[name], f64), 1090 + c * 80, 700, 78)
    text.append((1090, 708, 12, "at 64 px: a 5 stud body 64 px tall", soft))
    for i, (kind, label) in enumerate((("Color", "the colour map, 1024 px"), ("Emissive", "the glow mask"))):
        atlas = rs.load(paths[kind])
        atlas[..., 3] = 1.0
        rs.paste(page, rs.shrink(atlas, 250 / SIZE), 1090 + i * 270, 750)
        text.append((1090 + i * 270, 1006, 12, label, soft))
    for i, line in enumerate(facts):
        text.append((1640, 580 + i * 22, 13, line, ink))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "watt_model_sheet.png")
    rs.save(rs.shrink(page, 0.5), out / "watt_model_sheet_small.png")


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
    rs.save(page, out / "watt_atlas_check.png")


def main():
    out = bl.out_dir()
    rs.OUT = ws.OUT = out
    asked = sys.argv[sys.argv.index("--") + 2:]
    if "cpu" in asked:
        bl.use_gpu = lambda scene: setattr(scene.render, "engine", "CYCLES")
    scene = bl.reset_scene()
    joints = ws.build(scene, model=True)
    pivots = {key: tuple(joints[key].location) for key in JOINTS}
    surfaces()
    groups = take_pieces(joints)
    hidden = total = 0
    for index, piece in enumerate(PIECES):
        h, t = rm.mark_faces(groups[piece], index)
        hidden, total = hidden + h, total + t
        for o in groups[piece]:
            lit = [slot.material and slot.material.name in LIT for slot in o.material_slots]
            if any(lit):  # a lit surface takes its swatch, one flat block on every map: unwrapped, a small lit island
                # is a drop of its colour on the colour map (the content check on Pip's flame, 2026-11-12)
                flags = [1 if lit[p.material_index] else u for p, u in zip(o.data.polygons, rm.face_values(o.data, "unseen"))]
                o.data.attributes["unseen"].data.foreach_set("value", flags)
            o.data.transform(Matrix.Translation((APART * index, 0, 0)))
    kept, rm.APART = rm.APART, APART
    try:
        whole = bl.join([o for piece in PIECES for o in groups[piece]], "Watt")
        area, density = rm.unwrap(whole, SURFACES, LIT)
        print(f"faces {total}, unseen {hidden}; seen area {area:.1f} sq studs; {density:.0f} px per stud at {SIZE}", flush=True)
        if "dry" in asked:
            whole.data.calc_loop_triangles()
            print(f"dry: {len(whole.data.loop_triangles)} triangles, {len(whole.material_slots)} surfaces", flush=True)
            xs = [v.co.x for v in whole.data.vertices]
            print("dry: vertices by slot", [sum(1 for x in xs if abs(x - APART * k) < APART / 2) for k in range(len(PIECES))], flush=True)
            bl.save_blend(out / "watt_dry.blend")
            return
        paths = rm.bake(whole, out, "Watt", SURFACES, PALETTE, GROUND, LIT, COLD, "watt_model.py", LIT)
        made = rm.split(whole, PIECES, "Watt")
    finally:
        rm.APART = kept
    recipe = export(made, paths, out, density, pivots)
    body = [v.co for piece, o in made.items() if piece != "Spear" for v in o.data.vertices]
    tall = max(p.z for p in body)
    wide = max(p.x for p in body) - min(p.x for p in body)
    facts = [f"{recipe['tris']} triangles in {len(made)} pieces", f"{tall:.2f} studs to his hair's top,", f"{wide:.2f} wide; the spear {ws.SPEAR + 0.12:.2f} long",
             f"one {SIZE} px atlas, {density:.0f} px per stud", "1 extra joint: the spear, on the Torso", "maps: colour, roughness, metalness,",
             "and a glow mask: hair's ends, discs", "what's painted is cut into the blocks:", "one flat surface a face"]
    print("; ".join(facts))
    review(joints, made, paths, recipe, out, facts, pivots)
    atlas_check(paths, out)


if __name__ == "__main__":
    main()
