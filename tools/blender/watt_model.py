"""Watt's model (AR11, delivery 2): his pieces on the R6 rig, one baked texture set, the exports and the review sheet.

blender.exe -b --factory-startup --python tools/blender/watt_model.py -- <out_dir>

How he sits on R6: as Pip and Kirra do. A rigid mesh for each of the six parts carries the body's own surface, so the
rig's blocks are hidden; the generator and its two coils are the Torso's. Two pieces have joints of their own. The
visor turns on a hinge on the head: up on his brow in its mesh, so he's himself with no clip playing, and a clip keys
it down over his eyes. The wrench is one piece on a joint on the torso, its pivot at the grip: at rest it stands planted
ahead of his right side, as take A has it, and the clips key it into his hands or into the street.

Everything shares one 1024 px atlas: colour with the contact shading baked in, roughness, metalness (the steel and the
copper), and a glow mask over what lights: the two coil caps and the gauge's needle (the Torso), the lens (the Visor)
and the jaw's two inner walls (the Wrench). Each lit surface sits on its swatch, one flat block on every map, and each
piece takes its own strength and tint. No normal map: the low mesh is the form.

Writes to <out_dir>: Watt_<Piece>.json (blcommon.export_mesh_json), Watt_<Map>.png, Watt.recipe.json,
watt_model.blend, watt_model_sheet.png and watt_atlas_check.png. The shapes come from watt_sheet.build(model=True),
the unwrap, the bake and the review's tools from rook_model.py. The bake is Cycles, under build/locks/blender.lock.
"""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import pip_model as pm  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402
import watt_sheet as ws  # noqa: E402

SIZE = rm.SIZE
APART = 16.0  # studs between the pieces while they bake: the wrench's head is 3.6 across
JOINTS = {"root": "Torso", "neck": "Head", "rs": "RightArm", "ls": "LeftArm", "rh": "RightLeg", "lh": "LeftLeg",
          "visor": "Visor", "tool": "Wrench"}
MOTORS = {"Visor": "Head", "Wrench": "Torso"}  # the piece on a joint of its own: the part that joint is on
PIECES = list(JOINTS.values())
PALETTE = ws.MODEL_PALETTE
# surface: (roughness, metalness). The metals keep most of their own colour: full metal goes black wherever the sky is.
SURFACES = {
    "Kiln": (0.86, 0.0), "KilnDeep": (0.88, 0.0), "Steel": (0.42, 0.55), "SteelDeep": (0.5, 0.5),
    "Graphite": (0.8, 0.0), "GraphiteDeep": (0.62, 0.0), "Copper": (0.4, 0.55), "CopperDeep": (0.5, 0.55),
    "Cream": (0.86, 0.0), "Skin": (0.62, 0.0), "SkinShade": (0.66, 0.0), "Ink": (0.5, 0.0),
    "LitCap": (0.35, 0.0), "LitLens": (0.2, 0.0), "LitJaw": (0.42, 0.55),
}
LIT = ("LitCap", "LitLens", "LitJaw")
GROUND = "Graphite"  # the colour map's tone past the islands
BEVELS = {"WrenchHead": 0.05, "Neck": 0.04, "Handle": 0.035, "Grip": 0.03, "Knot": 0.04, "ToeCap": 0.03, "KneePad": 0.025,
          "Buckle": 0.012, "Clip": 0.012, "SleeveCuff": 0.02, "LensRim": 0.012}
STORM = ws.PALETTE["Storm"]
# Each lit piece's EmissiveTint and EmissiveStrength: as he stands, and in Ground Wire's hold. The colour map under a
# glow multiplies it (rm.baked's `through`), so the caps and the lens glow white through their own Storm, and the
# jaw's steel takes Storm from its tint.
GLOW = {"Torso": ("#FFFFFF", 0.5, 2.0, "the two coil caps and the gauge's needle"),
        "Visor": ("#FFFFFF", 0.0, 7.0, "the lens"),
        "Wrench": (STORM, 0.0, 3.0, "the jaw's two inner walls")}
VISOR_DOWN = Quaternion((1, 0, 0), math.radians(-ws.VISOR_UP))  # the hinge's turn, from up on his brow to over his eyes


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
    """The build's objects by piece, finished and standing free in the model's frame."""
    groups = {piece: [o for o in joints[key].children if o.type == "MESH"] for key, piece in JOINTS.items()}
    for objs in groups.values():
        for o in objs:
            o.parent = None
            o.matrix_world = Matrix.Identity(4)
            if rm.base(o) in BEVELS:
                bl.bevel(o, BEVELS[rm.base(o)], segments=2)
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
    rest = ws.rest_wrench()
    turn = rest.to_3x3()
    middle = ws.slot_middle()
    up = Matrix.Translation(ws.VISOR_PIVOT) @ Matrix.Rotation(math.radians(ws.VISOR_UP), 4, "X") @ Matrix.Translation(-ws.VISOR_PIVOT)
    recipe = {
        "name": "Watt",
        "frame": "Roblox studs: Y up, the model on y = 0 facing -Z, HumanoidRootPart at (0, 3, 0)",
        "rig": "R6. Every piece carries the body's own surface: the six rig parts are hidden (Transparency 1), and "
               "the Head's face decal is removed. His face is on the Head piece. The generator and its coils are the "
               "Torso piece's.",
        "maps": {kind: path.name for kind, path in paths.items()},
        "texels_per_stud": round(density),
        "emissive": {
            "pieces": {f"Watt_{piece}": {"tint": tint, "cold": cold, "hot": hot, "lit": what}
                       for piece, (tint, cold, hot, what) in GLOW.items()},
            "note": "One mask for all three pieces; each takes its own EmissiveTint and EmissiveStrength: cold as he "
                    "stands, hot in Ground Wire's hold. Roblox multiplies the glow by the colour map, so the caps "
                    "and the lens glow white through their own Storm (the lens is a dark Storm glass with its light "
                    "out), and the jaw's steel takes Storm from its tint. The other five pieces take no glow, and "
                    "the face none, ever. DESIGN: the strengths are the review sheet's, untried in Studio."},
        "pieces": pieces,
        "motors": {
            "Visor": {"axis": rm.roblox((1, 0, 0)), "down": -ws.VISOR_UP,
                      "note": "A hinge on the Head at his temples. With no turn it's up on his brow, which is its "
                              "mesh. Turned `down` degrees about `axis` at its pivot, it covers his eyes: down for "
                              "a fight, up again after a win. The clips key it."},
            "Wrench": {"along": rm.roblox(turn @ Vector((0, 0, 1))), "across": rm.roblox(turn @ Vector((1, 0, 0))),
                       "note": "One piece on the Torso, its pivot at the grip's middle. With no turn it stands "
                               "planted ahead of his right side, its rod 0.3 studs under y = 0. `along` is the "
                               "handle's line, from the rod to the head; `across` is the head's width. The clips "
                               "key it into his hands, and into the street for Ground Wire."}},
        "points": [
            {"name": "CoilR", "on": "Torso", "at": rm.roblox((ws.COIL_X, ws.PACK_Y, 5.52)), "note": "the right coil's cap: where an arc starts"},
            {"name": "CoilL", "on": "Torso", "at": rm.roblox((-ws.COIL_X, ws.PACK_Y, 5.52)), "note": "the left coil's cap"},
            {"name": "Gauge", "on": "Torso", "at": rm.roblox((0.46, ws.PACK_Y - 0.5, 3.62)), "note": "the gauge's face, on the camera's side"},
            {"name": "Chest", "on": "Torso", "at": rm.roblox((0, 0.62, 3.2)), "note": "where a hit lands"},
            {"name": "Lens", "on": "Watt_Visor", "at": rm.roblox(up @ Vector((0, 0.8, 4.5))), "note": "the lens's middle on the mesh as it is, the visor up: it turns with the hinge, to (0, 4.5, -0.8) with the visor down"},
            {"name": "Jaw", "on": "Watt_Wrench", "at": rm.roblox(rest @ Vector((ws.gap_across(middle), 0, middle))), "note": "the middle of the jaw's gap: where the coils' arcs land"},
            {"name": "Rod", "on": "Watt_Wrench", "at": rm.roblox(rest @ Vector((0, 0, ws.PLANTED))), "note": "where the rod meets the street, planted: where Ground Wire's ring starts"},
            {"name": "Grip", "on": "Watt_Wrench", "at": rm.roblox(ws.rest_grip()), "note": "the grip's middle: the joint's pivot"}],
        "tris": total,
    }
    (out / "Watt.recipe.json").write_text(json.dumps(recipe, indent=1))
    return recipe


# --- the review -------------------------------------------------------------------------------------------------

FACE = (168, 0)
HEAD = (0, 0, 4.7)
MID, FAR = (0.9, 0.2, 2.9), (0.2, 1.2, 2.7)
MET = (165, 6)  # Ground Wire's hold, from the Shades' side


def review(joints, made, paths, recipe, out, facts, pivots):
    scene = bpy.context.scene
    plain = rm.baked("Watt_Plain", paths, 0.0)
    states = {piece: {state: rm.baked(f"Watt_{piece}_{state}", paths, glow, tint, through=True) if glow else plain
                      for state, glow in (("cold", cold), ("hot", hot))}
              for piece, (tint, cold, hot, _) in GLOW.items()}
    for piece, o in made.items():
        bl.assign_only(o, states[piece]["cold"] if piece in states else plain)
    bl.save_blend(out / "watt_model.blend")  # the pieces standing free in the model's frame, for the clips' rig
    home = {}
    for piece, o in made.items():
        key = next(k for k, p in JOINTS.items() if p == piece)
        o.parent = joints[key]
        o.matrix_parent_inverse = Matrix.Translation(-Vector(pivots[key]))
        home[key] = joints[key].location.copy()
    span, px = 10.4, 700
    shots = {}

    def take(name, pose, view, at=MID, across=span, dusk=False, clay=False, size=px, bare=False):
        for key in JOINTS:
            joints[key].rotation_quaternion = (1, 0, 0, 0)
            joints[key].location = home[key]
        ws.POSES[pose](joints)
        if not ws.VISOR[pose]:
            joints["visor"].rotation_quaternion = VISOR_DOWN
        for piece, state in states.items():
            bl.assign_only(made[piece], state["hot" if pose == "wire" else "cold"])
        made["Wrench"].hide_render = bare
        if clay:
            rs.workbench(scene, size, size)
        else:
            rm.eevee(scene, size, size)
            pm.lighting(scene, view[0], dusk)
        path = out / f"_{name}.png"
        shots[name] = rs.shoot(scene, path, view[0], view[1], at, across)
        path.unlink()

    take("front", "square", (180, 4))
    take("back", "square", (0, 4))
    take("side", "square", (90, 4))
    take("quarter", "stood", ws.FRONT)
    take("game", "stood", ws.GAME)
    take("clay", "stood", ws.FRONT, clay=True)
    take("met", "wire", MET, at=FAR, across=11.0)
    take("wire", "wire", ws.GAME, at=FAR, across=11.0)
    take("face", "stood", FACE, at=HEAD, across=3.6, size=520, bare=True)
    take("facedusk", "stood", FACE, at=HEAD, across=3.6, size=520, dusk=True, bare=True)
    take("facedown", "wire", FACE, at=(0, 0.9, 4.1), across=3.6, size=520, bare=True)
    take("quarterdusk", "stood", ws.FRONT, dusk=True)
    take("gamedusk", "stood", ws.GAME, dusk=True)
    take("wiredusk", "wire", ws.GAME, at=FAR, across=span, dusk=True)
    take("wiresmall", "wire", ws.GAME, at=FAR, across=span)

    W, H = 1920, 1060
    ink, soft = "#1E1B22", "#6A6670"
    page = rs.canvas(W, H, rs.PAPER)
    text = [(30, 24, 30, "WATT, the model on R6", ink),
            (30, 62, 15, "AR11, delivery 2. Lit as the baked maps draw, the sun over the camera's left shoulder. No bloom: the game's, if any, is the builder's.", soft)]
    k = 0.76
    for i, (name, label) in enumerate((("front", "front, square, the wrench at its rest"), ("back", "back"), ("side", "his right side"),
                                       ("quarter", "three-quarter, how he stands (take A)"), ("game", "the player's camera"))):
        x = 10 + i * 322
        rs.stand(page, rs.shrink(shots[name], k), x, 520, 322)
        text.append((x + 20, 530, 14, label, soft))
    row = (("met", "Ground Wire's hold, from the Shades' side: lit", 0.66, 10, 400), ("wire", "the same, the player's camera", 0.66, 410, 330),
           ("clay", "the form alone", 0.5, 740, 250))
    for name, label, kk, x, width in row:
        rs.stand(page, rs.shrink(shots[name], kk), x, 1010, width)
        text.append((x + 20, 1020, 14, label, soft))
    faces = (("face", "the face, the visor up, by day", None), ("facedusk", "the same, at dusk", ws.DUSK),
             ("facedown", "the visor down, the lens lit", None))
    for i, (name, label, ground) in enumerate(faces):
        x = 1000 + i * 208
        if ground is not None:
            rs.fill(page, x, 806, 200, 200, ground)
        rs.paste(page, rs.shrink(shots[name], 200 / 520), x, 806)
        text.append((x + 4, 1020, 13, label, soft))
    rs.fill(page, 1000, 560, 616, 222, ws.DUSK)
    for i, name in enumerate(("quarterdusk", "gamedusk")):
        rs.stand(page, rs.shrink(shots[name], 0.46), 1000 + i * 308, 778, 308)
    text.append((1004, 786, 13, "the cream cuffs, lit as Lantern Row's dusk: the arms part from the street", soft))
    # the 64 px read: a 5 stud body 64 px tall, over a dark ground, Lantern Row's dusk, a bright one, and as outlines
    f64 = 64 / (5 * px / span)
    x0, y0 = 1626, 24
    grounds = ((rs.NIGHT, "64 px, dark ground", ("game", "quarter", "wiresmall"), False),
               (ws.DUSK, "64 px, Lantern Row's dusk, lit as dusk", ("gamedusk", "quarterdusk", "wiredusk"), False),
               (rs.DAY, "64 px, bright ground", ("game", "quarter", "wiresmall"), False),
               (rs.PAPER, "64 px, outline", ("game", "quarter", "wiresmall"), True))
    for r, (ground, label, names, sil) in enumerate(grounds):
        y = y0 + r * 126
        rs.fill(page, x0, y, 290, 106, ground)
        for c, name in enumerate(names):
            shot = rs.shrink(shots[name], f64)
            rs.stand(page, rs.black(shot) if sil else shot, x0 + 2 + c * 96, y + 104, 94)
        text.append((x0, y + 108, 12, label, soft))
    for i, (kind, label) in enumerate((("Color", "the colour map, 1024 px"), ("Emissive", "the glow mask"))):
        atlas = rs.load(paths[kind])
        atlas[..., 3] = 1.0
        rs.paste(page, rs.shrink(atlas, 140 / SIZE), x0 + i * 150, 540)
        text.append((x0 + i * 150, 684, 12, label, soft))
    for i, line in enumerate(facts):
        text.append((x0, 716 + i * 21, 12, line, ink))
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


def turn_a_head(mesh):
    """The wrench head's two faces are the atlas's two largest islands, and the packer lays them back to back: two
    crescents that read as a mirrored letter pair at 64 px (the content check on the model, 2026-11-15). The one on
    the right is turned half round in its own box, so both open the same way; nothing else moves."""
    uv = mesh.uv_layers.active.uv
    unseen = rm.face_values(mesh, "unseen")
    parent = {}

    def find(a):
        while parent.setdefault(a, a) != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    seen = [poly for poly in mesh.polygons if not unseen[poly.index]]
    for poly in seen:  # faces that share a corner at the same place on the map are one island
        keys = [(mesh.loops[i].vertex_index, round(uv[i].vector.x, 5), round(uv[i].vector.y, 5))
                for i in range(poly.loop_start, poly.loop_start + poly.loop_total)]
        for key in keys:
            parent[find(key)] = find(("f", poly.index))
    islands = {}
    for poly in seen:
        pts = [uv[i].vector for i in range(poly.loop_start, poly.loop_start + poly.loop_total)]
        area = abs(sum(pts[k].x * pts[(k + 1) % len(pts)].y - pts[(k + 1) % len(pts)].x * pts[k].y for k in range(len(pts)))) / 2
        entry = islands.setdefault(find(("f", poly.index)), [0.0, []])
        entry[0] += area
        entry[1].append(poly)
    first, second = sorted(islands.values(), key=lambda e: -e[0])[:2]

    def box(entry):
        pts = [uv[i].vector for poly in entry[1] for i in range(poly.loop_start, poly.loop_start + poly.loop_total)]
        return min(p.x for p in pts), min(p.y for p in pts), max(p.x for p in pts), max(p.y for p in pts)

    turned = max((first, second), key=lambda e: box(e)[0])
    x0, y0, x1, y1 = box(turned)
    for poly in turned[1]:
        for i in range(poly.loop_start, poly.loop_start + poly.loop_total):
            u, v = uv[i].vector
            uv[i].vector = (x0 + x1 - u, y0 + y1 - v)
    print(f"the two largest islands: {first[0] * SIZE * SIZE:.0f} and {second[0] * SIZE * SIZE:.0f} sq px; the right one "
          f"turned half round in its box ({x0 * SIZE:.0f}, {y0 * SIZE:.0f}) to ({x1 * SIZE:.0f}, {y1 * SIZE:.0f})")


def main():
    out = bl.out_dir()
    rs.OUT = ws.OUT = out
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
        turn_a_head(whole.data)
        print(f"faces {total}, unseen {hidden}; seen area {area:.1f} sq studs; {density:.0f} px per stud at {SIZE}")
        paths = rm.bake(whole, out, "Watt", SURFACES, PALETTE, GROUND, LIT, {}, "watt_model.py", LIT)
        made = rm.split(whole, PIECES, "Watt")
    finally:
        rm.APART = kept
    recipe = export(made, paths, out, density, pivots)
    body = [v.co for piece, o in made.items() if piece != "Wrench" for v in o.data.vertices]
    everything = [v.co for o in made.values() for v in o.data.vertices]
    tall = max(p.z for p in body)
    wide = max(p.x for p in body) - min(p.x for p in body)
    across = max(p.x for p in everything) - min(p.x for p in everything)
    facts = [f"{recipe['tris']} triangles in {len(made)} pieces", f"{tall:.2f} studs to the coils' caps, {wide:.2f} wide,",
             f"{across:.2f} across with the wrench at rest", f"one {SIZE} px atlas, {density:.0f} px per stud",
             "2 extra joints: the visor's hinge, the wrench", "maps: colour, roughness, metalness,",
             "and a glow mask: caps, needle, lens, jaw", "the short sleeves end in cream cuffs"]
    print("; ".join(facts))
    review(joints, made, paths, recipe, out, facts, pivots)
    atlas_check(paths, out)


if __name__ == "__main__":
    main()
