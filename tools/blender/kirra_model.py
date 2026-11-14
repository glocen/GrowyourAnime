"""Kirra's model (AR10, delivery 2): her pieces on the R6 rig, one baked texture set, the exports and the review sheet.

blender.exe -b --factory-startup --python tools/blender/kirra_model.py -- <out_dir>

How she sits on R6: a rigid mesh for each of the six parts, which carries the body's own surface, so the rig's blocks
are hidden and the Head's face decal goes; and ten pieces on joints of their own.
- The scarf's tail, 10 studs, is a chain of LINKS segments, each on a joint at its root: the first on the Torso at the
  knot, each next on the one before. Each segment keeps its stretch of the rest S in its mesh, so she's herself with no
  clip playing, and a stretch bends so little that, keyed in a line, the chain draws Scarf Step's straight line. A bend
  at a joint opens no gap: each segment carries a thin half-disc back into the one before, hidden inside the band at
  rest, and the segments are by turns a little thinner, so where two overlap they never draw on one plane.
- The two blades, a piece each, at rest in their sheaths crossed on her back. Each rides a joint of its own on the
  Torso at its grip, as Pip's lantern does: the clips that draw it key it into her fist, and any other clip leaves it
  home. The recipe gives each one's pivot and grip frame. The empty sheaths stay on the Torso.
Everything shares one 1024 px atlas: colour with the contact shading baked in, roughness, metalness (the steel). No
glow and no normal map: the low mesh is the form.

Writes to <out_dir>: Kirra_<Piece>.json (blcommon.export_mesh_json), Kirra_<Map>.png, Kirra.recipe.json,
kirra_model.blend, kirra_model_sheet.png and kirra_atlas_check.png. The shapes come from kirra_sheet.build(model=True),
with research's two fixes on the sheet; the unwrap, the bake and the review's tools from rook_model.py. The bake is
Cycles, under build/locks/blender.lock.
"""
import json
import math
import sys
import time
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import kirra_sheet as ks  # noqa: E402
import pip_model as pm  # noqa: E402
import pip_sheet as ps  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402

SIZE = rm.SIZE
APART = 16.0  # studs between the pieces while they bake: wider than Rook's 10, for the satchel's side of the torso
LINKS = 8     # the scarf's joints
RINGS = 24    # rings a segment, along its length
THICK = (0.07, 0.064)  # the band, studs: the segments by turns, so an overlap at a bent joint never shares a plane
END = 0.55    # the tail's last half-stud, in bone
BODY = {"root": "Torso", "neck": "Head", "rs": "RightArm", "ls": "LeftArm", "rh": "RightLeg", "lh": "LeftLeg"}
BLADES = {"BladeR": ("Right", "Right Arm", "GripR", "rs"), "BladeL": ("Left", "Left Arm", "GripL", "ls")}
SCARF = [f"Scarf{k + 1}" for k in range(LINKS)]
PIECES = [*BODY.values(), *BLADES, *SCARF]
# surface: (roughness, metalness). The steel keeps most of its own colour: full metal goes black wherever the sky is.
SURFACES = {
    "Sky": (0.8, 0.0), "SkyDeep": (0.55, 0.0), "Navy": (0.88, 0.0), "NavyLift": (0.88, 0.0), "Saffron": (0.62, 0.0),
    "Bone": (0.9, 0.0), "BoneShade": (0.9, 0.0), "Leather": (0.7, 0.0), "LeatherLight": (0.7, 0.0),
    "LeatherDeep": (0.75, 0.0), "Steel": (0.32, 0.55), "SteelDeep": (0.45, 0.45), "Soot": (0.72, 0.0),
    "Skin": (0.65, 0.0), "Ink": (0.5, 0.0),
}
UNLIT = ("Unlit",)  # no surface of hers glows: the bake's mask comes out black, and isn't handed off
GROUND = "Navy"     # the colour map's tone past the islands
BEVELS = {"Satchel": 0.04, "Flap": 0.012, "FlapTop": 0.012, "Parcel": 0.02, "Buckle": 0.012, "SatchelBuckle": 0.012,
          "Knot": 0.06, **{f"{side}{part}": w for side in ("Right", "Left") for part, w in
                           (("Sheath", 0.02), ("Throat", 0.015), ("Chape", 0.015))},
          **{f"{blade}{part}": w for blade in BLADES for part, w in (("Pommel", 0.02), ("Guard", 0.015))}}
HAND = 2.0  # the fist's middle, the height of R6's hand at rest: r6rig.GRIP, (0, -1, 0) on the arm
# The blade, drawn in its own plane (across it, down its line from the pommel's end): the edge straight, the back
# clipped to the point
STEEL = [(-0.09, 0.61), (0.11, 0.61), (0.11, 1.73), (0.0, 2.05), (-0.09, 1.85)]
TIP = 2.05


# --- the scarf's chain --------------------------------------------------------------------------------------------

def rest_tail():
    """The tail at rest as the sheet lays it (kirra_sheet.lay_rest_tail at heading 0), sampled evenly, LINKS * RINGS
    steps, so every joint falls on a ring: (s, point, along, across, normal, width) for each ring."""
    path = bl.smooth_path(ks.REST, samples=480)
    knot = Vector(ks.KNOT)
    scale = ks.TAIL / ks.run_length(path)[-1]
    path = [knot + (p - knot) * scale for p in path]
    run = ks.run_length(path)
    total = run[-1]
    count = LINKS * RINGS
    points, j = [], 0
    for i in range(count + 1):
        s = total * i / count
        while j < len(run) - 2 and run[j + 1] < s:
            j += 1
        points.append(path[j].lerp(path[j + 1], (s - run[j]) / max(run[j + 1] - run[j], 1e-9)))
    rings = []
    for i, p in enumerate(points):
        s = total * i / count
        t = (points[min(i + 1, count)] - points[max(i - 1, 0)]).normalized()
        w = Vector((0, 0, 1)) - t * t.z
        w = w.normalized() if w.length > 1e-4 else Vector((1, 0, 0))
        w = Quaternion(t, math.radians(35.0 * math.sin(2 * math.pi * 1.2 * s / total))) @ w  # kirra_sheet.tail's twist
        rings.append((s, p, t, w, t.cross(w).normalized(), 0.72 - 0.14 * s / total))
    return rings


def ring_at(rings, s):
    """The band's frame at s along it, between its rings."""
    step = rings[1][0] - rings[0][0]
    i = max(0, min(int(s / step), len(rings) - 2))
    f = (s - rings[i][0]) / step
    a, b = rings[i], rings[i + 1]
    t = a[2].lerp(b[2], f).normalized()
    w = a[3].lerp(b[3], f)
    w = (w - t * w.dot(t)).normalized()
    return a[1].lerp(b[1], f), t, w, t.cross(w).normalized(), a[5] + (b[5] - a[5]) * f


def band(name, rings, thick, material, wider=1.0):
    """The flat band through `rings`, closed at both ends."""
    bm = bmesh.new()
    loops = [[bm.verts.new(p + w * (width * wider / 2) * a + n * (thick / 2) * b)
              for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))] for s, p, t, w, n, width in rings]
    for a, b in zip(loops, loops[1:]):
        for k in range(4):
            bm.faces.new((a[k], a[(k + 1) % 4], b[(k + 1) % 4], b[k]))
    bm.faces.new(list(reversed(loops[0])))
    bm.faces.new(loops[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bl.object_from_bmesh(name, bm, material)


def filler(name, rings, s0, radius, half, material, rows=8, cols=7):
    """A half-disc of `radius` about the joint at s0, reaching back along the band and laid on it, `half` either side
    of its middle: inside the band at rest, it fills the wedge that a bend at the joint opens."""
    xs = [-radius * math.cos(math.pi / 2 * i / (rows - 2)) for i in range(rows - 1)] + [0.02]
    bm = bmesh.new()
    grid = []
    for x in xs:
        p, t, w, n, _ = ring_at(rings, s0 + x)
        across = max(math.sqrt(max(radius * radius - x * x, 0.0)) if x < 0 else radius, 0.012)
        row = []
        for k in range(cols):
            on = p + w * (across * (-1 + 2 * k / (cols - 1)))
            row.append((bm.verts.new(on + n * half), bm.verts.new(on - n * half)))
        grid.append(row)
    for a, b in zip(grid, grid[1:]):
        for k in range(cols - 1):
            bm.faces.new((a[k][0], a[k + 1][0], b[k + 1][0], b[k][0]))
            bm.faces.new((a[k][1], b[k][1], b[k + 1][1], a[k + 1][1]))
        for k in (0, cols - 1):
            bm.faces.new((a[k][0], b[k][0], b[k][1], a[k][1]))
    for row in (grid[0], grid[-1]):
        for k in range(cols - 1):
            bm.faces.new((row[k][0], row[k][1], row[k + 1][1], row[k + 1][0]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bl.object_from_bmesh(name, bm, material)


def make_scarf(rings, m):
    """The tail's segments, each with what rides its joint: {piece: [objects]}, and how far the most bent segment
    strays from its chord, studs."""
    groups, sag = {}, 0.0
    total = rings[-1][0]
    for j, piece in enumerate(SCARF):
        own = rings[j * RINGS:(j + 1) * RINGS + 1]
        thick = THICK[j % 2]
        if j == LINKS - 1:
            cut = next(i for i, r in enumerate(own) if r[0] >= total - END)
            objs = [band("ScarfBand", own[:cut + 1], thick, m["Sky"]), band("ScarfEnd", own[cut:], thick + 0.005, m["Bone"], 1.02)]
        else:
            objs = [band("ScarfBand", own, thick, m["Sky"])]
        if j:
            objs.append(filler("ScarfFill", rings, own[0][0], own[0][5] / 2 - 0.012, min(THICK) / 2 - 0.006, m["Sky"]))
        groups[piece] = objs
        a, b = own[0][1], own[-1][1]
        chord = (b - a).normalized()
        sag = max(sag, max(((r[1] - a) - chord * (r[1] - a).dot(chord)).length for r in own))
    return groups, sag


# --- the blades ---------------------------------------------------------------------------------------------------

def frame(at, length, back):
    """A grip frame as a matrix: X = length x back, Y the length, Z the back, at `at`."""
    x = length.cross(back)
    return Matrix(((x.x, length.x, back.x, at.x), (x.y, length.y, back.y, at.y), (x.z, length.z, back.z, at.z), (0, 0, 0, 1)))


def sheath_axes(side):
    """The sheath's line, from the throat's top, and its width: kirra_sheet.bar's slab, turned about Y."""
    top, tip = (Vector(p) for p in ks.SHEATHS[side])
    d = (tip - top).normalized()
    beta = math.atan2(d.x, d.z)
    return top, d, Vector((math.cos(beta), 0, -math.sin(beta)))


def blade_grip(side):
    """Where the fist closes on the blade at rest, in its sheath: (the point, the line to the tip, the back)."""
    top, d, across = sheath_axes(side)
    return top + d * ks.GRIP, d, across


def make_blade(piece, m):
    """A short blade, as it sits in its sheath: the steel pommel, the saffron grip, the guard, and the steel."""
    top, d, across = sheath_axes(BLADES[piece][0])
    depth = Vector((0, 1, 0))  # the blade's flat faces her back and away from it
    place = Matrix(((depth.x, -across.x, d.x, top.x), (depth.y, -across.y, d.y, top.y), (depth.z, -across.z, d.z, top.z), (0, 0, 0, 1)))
    objs = [rs.slab(f"{piece}Pommel", (0, 0, 0.035), (0.2, 0.2, 0.07), m["SteelDeep"]),
            rs.slab(f"{piece}Grip", (0, 0, ks.GRIP), (0.16, 0.16, 0.48), m["Saffron"]),
            rs.slab(f"{piece}Guard", (0, 0, 0.58), (0.22, 0.38, 0.06), m["SteelDeep"]),
            bl.profile(f"{piece}Steel", STEEL, 0.05, m["Steel"])]
    for o in objs:
        o.data.transform(place)
    return objs


# --- the pieces ---------------------------------------------------------------------------------------------------

def surfaces():
    for name, (rough, metal) in SURFACES.items():
        m = bpy.data.materials[name]
        if not (m.node_tree and m.node_tree.nodes.get("Principled BSDF")):
            m.use_nodes = True
        bsdf = m.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = tuple(m.diffuse_color)
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = metal


def take_pieces(joints, made):
    """The build's objects by piece, with the blades and the scarf's segments, finished and standing free in the model's
    frame."""
    groups = {piece: [o for o in joints[key].children if o.type == "MESH"] for key, piece in BODY.items()}
    groups.update(made)
    for objs in groups.values():
        for o in objs:
            o.parent = None
            o.matrix_world = Matrix.Identity(4)
            if rm.base(o) in BEVELS:
                bl.bevel(o, BEVELS[rm.base(o)], segments=2)
            bl.smooth_by_angle(o, 32)
    return groups


# --- the hand-off -------------------------------------------------------------------------------------------------

def export(made, paths, out, density, rings, sag):
    """Each piece as JSON for Studio, and the recipe's facts. Points are Roblox's: studs, Y up, the model standing
    on y = 0 and facing -Z, its HumanoidRootPart at (0, 3, 0)."""
    pieces, total = [], 0
    for piece, o in made.items():
        tris = bl.export_mesh_json(o, out / f"{o.name}.json")
        total += tris
        box = [v.co for v in o.data.vertices]
        size = [round(max(c[i] for c in box) - min(c[i] for c in box), 3) for i in (0, 2, 1)]
        entry = {"name": o.name, "mesh": f"{o.name}.json", "centre": json.loads((out / f"{o.name}.json").read_text())["c"],
                 "size": size, "tris": tris}
        if piece in BLADES:
            side = BLADES[piece][0]
            at, length, back = blade_grip(side)
            entry.update({"on": "Torso", "motor": piece, "pivot": rm.roblox(at),
                          "grip": {"at": rm.roblox(at), "length": rm.roblox(length), "back": rm.roblox(back)}})
        elif piece in SCARF:
            j = SCARF.index(piece)
            _, p, t, w, _, _ = rings[j * RINGS]
            entry.update({"on": "Torso" if j == 0 else f"Kirra_{SCARF[j - 1]}", "motor": piece, "pivot": rm.roblox(p),
                          "along": rm.roblox(t), "across": rm.roblox(w)})
        else:
            entry["on"] = rm.R6[piece]
        pieces.append(entry)
        print(f"{o.name}: {tris} tris, {size} studs")
    recipe = {
        "name": "Kirra",
        "frame": "Roblox studs: Y up, the model on y = 0 facing -Z, HumanoidRootPart at (0, 3, 0)",
        "rig": "R6. Every piece carries the body's own surface: the six rig parts are hidden (Transparency 1), and "
               "the Head's face decal is removed. Her face is on the Head piece.",
        "maps": {kind: path.name for kind, path in paths.items()},
        "texels_per_stud": round(density),
        "glow": "none: no emissive mask, and nothing of hers is lit",
        "pieces": pieces,
        "scarf": {
            "joints": SCARF, "length": ks.TAIL, "straight_within": round(sag, 3),
            "note": "The tail is a chain: each segment rides a Motor6D at its root, named as the piece, on the segment "
                    "before it (the first on the Torso, at the knot), so they're made root to tip. A joint's frame is "
                    "its pivot with the model's axes at rest, as Pip's. With every Transform at rest the tail floats in "
                    "its S. 'along' is the band's line at the pivot and 'across' its width: a turn about 'across' "
                    "ripples the band, one about its face swings it edgewise, and a half-disc in each segment fills the "
                    "wedge that opens. Keyed with every segment's chord on one line (Scarf Step), the scarf is straight "
                    "to within 'straight_within' studs. The clips key the shapes they mean; whether a spring in code "
                    "trails it through the world between them is the builder's call (a clip can't see her run). It "
                    "casts a shadow."},
        "blades": {
            "note": "Each blade is one piece on a Motor6D of its own on the Torso, named in 'motor', its frame at "
                    "'pivot' (the grip's middle) with the model's axes at rest, as the scarf's joints are. With its "
                    "Transform at rest it sits in its sheath, crossed on her back; a clip that draws it keys it into her "
                    "fist frame by frame, wherever the hand is, and puts it back. A clip that never keys it (the shared "
                    "walk, the open reactions) leaves it home. 'grip' is the blade's frame at rest: 'length' from pommel "
                    "to point, 'back' its spine. The empty sheaths are on the Torso piece."},
        "points": [{"name": "Knot", "on": "Torso", "at": rm.roblox(ks.KNOT), "note": "the scarf's knot: Scarf Step's line leaves from here"},
                   {"name": "ScarfTip", "on": f"Kirra_{SCARF[-1]}", "at": rm.roblox(rings[-1][1]), "note": "the tail's bone end"},
                   {"name": "Chest", "on": "Torso", "at": rm.roblox((0, 0.6, 3.2)), "note": "where a hit lands"},
                   *[{"name": f"Tip{piece[-1]}", "on": f"Kirra_{piece}",
                      "at": rm.roblox(sheath_axes(BLADES[piece][0])[0] + sheath_axes(BLADES[piece][0])[1] * TIP),
                      "note": "the blade's point: a cut's arc"} for piece in BLADES]],
        "tris": total,
    }
    (out / "Kirra.recipe.json").write_text(json.dumps(recipe, indent=1))
    return recipe


# --- the review: the rig and its poses ----------------------------------------------------------------------------

def chain(joints, rings):
    """Empties for the scarf's joints, each on the one before, at the pivots: {key: pivot}."""
    parent, at = joints["root"], Vector(ks.PIVOTS["root"])
    pivots = {}
    for j in range(LINKS):
        pivot = rings[j * RINGS][1]
        e = bpy.data.objects.new(f"scarf{j + 1}", None)
        bpy.context.scene.collection.objects.link(e)
        e.rotation_mode = "QUATERNION"
        e.parent = parent
        e.matrix_parent_inverse = Matrix.Translation(-at)
        e.location = pivot
        joints[f"scarf{j + 1}"] = e
        pivots[f"scarf{j + 1}"] = pivot
        parent, at = e, pivot
    return pivots


def hold(made, joints, pivots, piece, drawn):
    """A blade in its sheath on her back, or in her fist: its grip frame on the hand's (r6rig.GRIP)."""
    o = made[piece]
    side, _, _, key = BLADES[piece]
    if drawn:
        hand = frame(Vector((1.5 if key == "rs" else -1.5, 0, HAND)), Vector((0, 1, 0)), Vector((0, 0, 1)))
        o.parent = joints[key]
        o.matrix_parent_inverse = Matrix.Translation(-Vector(pivots[key])) @ hand @ frame(*blade_grip(side)).inverted()
    else:
        o.parent = joints["root"]
        o.matrix_parent_inverse = Matrix.Translation(-Vector(pivots["root"]))


def level(joints, heading):
    """The tail kept level on her heading however the torso leans, as the sheet lays it: the first joint undoes the
    torso's turn but for the heading."""
    bpy.context.view_layer.update()
    body = joints["root"].matrix_world.to_quaternion()
    joints["scarf1"].rotation_quaternion = body.inverted() @ Matrix.Rotation(math.radians(heading), 4, "Z").to_quaternion()


def straighten(joints, rings, direction):
    """Every segment's chord on one line from the knot: Scarf Step."""
    tip = rings[-1][1] - rings[(LINKS - 1) * RINGS][1]
    for j in range(LINKS):
        bpy.context.view_layer.update()
        joint = joints[f"scarf{j + 1}"]
        here = joint.matrix_world.translation
        there = (joints[f"scarf{j + 2}"].matrix_world.translation if j + 1 < LINKS
                 else joint.matrix_world @ tip)
        turn = (there - here).rotation_difference(direction)
        parent = joint.parent.matrix_world.to_quaternion()
        joint.rotation_quaternion = parent.inverted() @ turn @ joint.matrix_world.to_quaternion()
    bpy.context.view_layer.update()


def wave(joints, rings):
    """The seam test: each joint bent 22 degrees across the band's face and 15 about its width, by turns."""
    for j in range(LINKS):
        _, _, t, w, n, _ = rings[j * RINGS]
        sign = 1 if j % 2 else -1
        joints[f"scarf{j + 1}"].rotation_quaternion = (Quaternion(n, math.radians(22 * sign)) @ Quaternion(w, math.radians(-15 * sign)))
    bpy.context.view_layer.update()


def pose_square(joints, rings):
    rs.aim(joints["rs"], Quaternion(), (0.2, 0.0, -1.0))
    rs.aim(joints["ls"], Quaternion(), (-0.2, 0.0, -1.0))
    rs.stand_on_floor(joints)
    return ()


def pose_idle(joints, rings):
    """kirra_sheet.pose_idle's body; the tail kept level on her heading."""
    body = ks.turn(-10, -16)
    joints["root"].rotation_quaternion = body
    rs.aim(joints["rs"], body, (0.16, 0.3, -1.0), stage=False)
    rs.aim(joints["ls"], body, (-0.1, -0.42, -1.0), stage=False)
    joints["neck"].rotation_quaternion = body.inverted() @ ks.turn(-4, -2)
    rs.aim(joints["rh"], body, (0.08, 0.42, -1.0), twist=-8)
    rs.aim(joints["lh"], body, (-0.1, -0.4, -1.0), twist=6)
    rs.stand_on_floor(joints)
    level(joints, -10)
    return ()


def pose_drawn(joints, rings):
    """Both blades out, held low and ahead: what the clips start from."""
    body = ks.turn(-8, -14)
    joints["root"].rotation_quaternion = body
    rs.aim(joints["rs"], body, (0.42, 0.62, -0.7), twist=-10)
    rs.aim(joints["ls"], body, (-0.46, 0.5, -0.78), twist=12)
    joints["neck"].rotation_quaternion = body.inverted() @ ks.turn(-6, -2)
    rs.aim(joints["rh"], body, (0.12, 0.4, -1.0), twist=-8)
    rs.aim(joints["lh"], body, (-0.12, -0.36, -1.0), twist=6)
    rs.stand_on_floor(joints)
    level(joints, -8)
    return ("BladeR", "BladeL")


def pose_step(joints, rings):
    """kirra_sheet.pose_step's body, the right blade out on the cut; the chain keyed straight back through the Shade."""
    u, r = ks.step_axes()
    down = Vector((0, 0, -1))
    heading = 180.0 - ks.STEP_ANGLE
    body = ks.turn(heading, -30)
    root = joints["root"]
    root.rotation_quaternion = body
    root.location = (ks.TARGET + u * ks.PAST).to_tuple()[:2] + (3.0,)
    rs.aim(joints["rh"], body, u * math.sin(math.radians(62)) + r * 0.12 + down * math.cos(math.radians(62)), twist=-10)
    rs.aim(joints["lh"], body, -u * math.sin(math.radians(52)) - r * 0.1 + down * math.cos(math.radians(52)))
    rs.aim(joints["rs"], body, u * 0.75 + r * 0.5 + down * 0.36, twist=-20)
    rs.aim(joints["ls"], body, -u * 0.72 - r * 0.32 + down * 0.5)
    joints["neck"].rotation_quaternion = body.inverted() @ ks.turn(heading, 12)
    rs.stand_on_floor(joints)
    knot = joints["scarf1"].matrix_world.translation
    straighten(joints, rings, (ks.TARGET + Vector((0, 0, 3.0)) - knot).normalized())
    return ("BladeR",)


def pose_wave(joints, rings):
    pose_square(joints, rings)
    wave(joints, rings)
    return ()


POSES = {"square": pose_square, "idle": pose_idle, "drawn": pose_drawn, "step": pose_step, "wave": pose_wave}
PX = 100  # pixels a stud in the full views, as the sheet's: the 64 px block shrinks them all by one factor
F64 = 64 / (5 * PX)
FACE = (164, 2)


def lit_material(name, code):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = rs.srgb(code)
    m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
    m.diffuse_color = rs.srgb(code)
    return m


# --- the review: before and after research's fixes, in the sheet's own drawing -------------------------------------

def light_share(shot):
    """Of the figure at 64 px (a picture at PX a stud), the share of pixels lighter than half: how much of her holds
    over a dark ground."""
    small = rs.shrink(rs.trim(shot), F64)
    seen = small[..., 3] > 0.5
    luma = small[..., :3] @ np.array((0.2126, 0.7152, 0.0722), dtype=np.float32)
    return float((seen & (luma > 0.5)).sum()) / max(int(seen.sum()), 1)


def compare(out):
    """The sheet's Kirra and the model's shapes, drawn alike (Workbench, the sheet's mix of passes): her back from the
    player's camera without the tail, which fix 1 is about, and the head from behind and from the player's camera, for
    fix 2."""
    ks.OUT = out
    shots = {}
    for model in (False, True):
        scene = bl.reset_scene()
        joints = ks.build(scene, model=model)
        ks.pose_idle(joints)
        for o in scene.objects:
            if o.type == "MESH" and o.parent is None:  # the tail, laid in the world
                o.hide_render = True
        shots[model, "back"] = rs.trim(ks.render(scene, "back", *ks.GAME, Vector((0, 0, 2.8)), 6.4, PX))
        for key in ks.PIVOTS:
            joints[key].rotation_quaternion = (1, 0, 0, 0)
        joints["root"].location = ks.PIVOTS["root"]
        for o in scene.objects:  # the head alone, standing square
            if o.type == "MESH":
                o.hide_render = o.parent is not joints["neck"]
        head = (Vector((0, 0, 4.75)), 1.9, 2 * PX)
        shots[model, "nape"] = rs.trim(ks.render(scene, "nape", 0, 4, *head))
        shots[model, "crown"] = rs.trim(ks.render(scene, "crown", *ks.GAME, *head))
    return shots


# --- the review sheet ---------------------------------------------------------------------------------------------

def review(joints, pivots, made, rings, paths, recipe, out, facts, before):
    scene = bpy.context.scene
    clay = rm.baked("Kirra_Baked", paths, 0.0)
    for o in made.values():
        bl.assign_only(o, clay)
    bl.save_blend(out / "kirra_model.blend")  # the pieces standing free in the model's frame, for the clips' rig
    for piece, o in made.items():
        key = next((k for k, p in BODY.items() if p == piece), None) or (f"scarf{SCARF.index(piece) + 1}" if piece in SCARF else None)
        if key:
            o.parent = joints[key]
            o.matrix_parent_inverse = Matrix.Translation(-Vector(pivots[key]))
    ghosts = ks.ghost({"Ghost": lit_material("GhostLit", ks.PALETTE["Ghost"])}, ks.TARGET)
    pin = lit_material("PinLit", ks.PALETTE["Ink"])
    dots = []
    for j in range(LINKS):  # a pin through the band at each joint, for the seam test
        dot = bl.cylinder("Pin", 0.07, 0.3, 12, pin)
        dot.parent = joints[f"scarf{j + 1}"]
        dot.matrix_parent_inverse = rings[j * RINGS][4].to_track_quat("Z", "Y").to_matrix().to_4x4()
        dots.append(dot)
    shots, numbers = {}, {}

    def take(name, pose, view, close=None, dusk=False, workbench=False, ghost=False, pins=False, bare=False):
        rm.rest(joints)
        drawn = POSES[pose](joints, rings)
        for piece in BLADES:
            hold(made, joints, pivots, piece, piece in drawn)
        for o in ghosts:
            o.hide_render = not ghost
        for o in dots:
            o.hide_render = not pins
        for piece in SCARF:
            made[piece].hide_render = bare
        bpy.context.view_layer.update()
        if close:
            centre, span, px = close
        else:
            pts = [o.matrix_world @ v.co for o in made.values() for v in o.data.vertices]
            low = Vector([min(q[i] for q in pts) for i in range(3)])
            high = Vector([max(q[i] for q in pts) for i in range(3)])
            centre, span, px = (low + high) / 2, (high - low).length * 1.02, PX
            numbers[pose, "size"] = tuple(round(high[i] - low[i], 2) for i in range(3))
            numbers[pose, "top"] = round(high.z, 2)
        size = math.ceil(span * px)
        if workbench:
            rs.workbench(scene, size, size)
        else:
            rm.eevee(scene, size, size)
            pm.lighting(scene, view[0], dusk)
        path = out / f"_{name}.png"
        shots[name] = rs.trim(rs.shoot(scene, path, view[0], view[1], centre, span))
        path.unlink()

    heading = 180.0 - ks.STEP_ANGLE
    take("front", "square", (180, 4))
    take("back", "square", (0, 4))
    take("side", "square", (90, 4))
    take("quarter", "idle", ps.FRONT)
    take("game", "idle", ks.GAME)
    take("clay", "idle", ps.FRONT, workbench=True)
    take("drawn", "drawn", (158, 8))
    take("drawngame", "drawn", ks.GAME)
    take("stepside", "step", ((heading + 90) % 360, 3), ghost=True)
    take("stepgame", "step", ks.GAME, ghost=True)
    rm.rest(joints)
    pose_wave(joints, rings)
    mid = sum((joints[f"scarf{j + 1}"].matrix_world.translation for j in range(1, 7)), Vector()) / 6
    take("wave", "wave", (42, 20), close=(mid, 5.2, 120), pins=True)
    take("face", "square", FACE, close=(Vector((0, 0, 4.62)), 2.5, 200))
    take("facedusk", "square", FACE, close=(Vector((0, 0, 4.62)), 2.5, 200), dusk=True)
    take("nape", "square", (24, 14), close=(Vector((0, 0, 4.4)), 3.0, 170))
    take("quarterdusk", "idle", ps.FRONT, dusk=True)
    take("gamedusk", "idle", ks.GAME, dusk=True)
    for dusk in (False, True):  # her back without the tail, as the maps draw it: fix 1's number on the model itself
        take("bare", "idle", ks.GAME, close=(Vector((0, 0, 2.8)), 6.4, PX), dusk=dusk, bare=True)
        numbers["dusk" if dusk else "day"] = light_share(shots["bare"])

    W, H = 1920, 1290
    ink, soft = "#1E1B22", "#6A6670"
    page = rs.canvas(W, H, rs.PAPER)
    text = [(30, 24, 30, "KIRRA, the model on R6", ink),
            (30, 62, 15, "AR10, delivery 2. Lit as the baked maps draw, the sun over the camera's left shoulder. Research's two fixes "
                         "on the sheet are made: a bone yoke on her back, and three swept points in the crop.", soft)]
    ks.fit_row(page, text, [(shots["front"], "front"), (shots["back"], "back"), (shots["side"], "her right side"),
                            (shots["quarter"], "how she stands"), (shots["game"], "the player's camera")], 20, 1530, 390, 300, soft, gap=30)
    ks.fit_row(page, text, [(shots["drawn"], "the blades drawn"), (shots["drawngame"], "the same, the player's camera"),
                            (shots["stepside"], "Scarf Step, the chain keyed straight"), (shots["stepgame"], "the player's camera"),
                            (shots["clay"], "the form alone")], 20, 1530, 770, 300, soft, gap=30)
    # row 3: the seam test, the face, the nape, and research's fixes before and after
    y3 = 830
    wave = shots["wave"]
    rs.stand(page, rs.shrink(wave, min(330 / wave.shape[1], 300 / wave.shape[0])), 20, y3 + 320, 330)
    text.append((24, y3 + 330, 14, "the seam test: every joint bent 22 and 15 degrees, by turns; a pin at each", soft))
    for i, (name, ground, label) in enumerate((("face", None, "the face, by day"), ("facedusk", ps.DUSK, "and at dusk"))):
        x = 370 + i * 190
        if ground is not None:
            rs.fill(page, x, y3 + 8, 182, 182, ground)
        face = shots[name]
        rs.stand(page, rs.shrink(face, min(182 / face.shape[0], 182 / face.shape[1])), x, y3 + 190, 182)
        text.append((x, y3 + 200, 14, label, soft))
    nape = shots["nape"]
    rs.stand(page, rs.shrink(nape, min(220 / nape.shape[1], 300 / nape.shape[0])), 750, y3 + 320, 220)
    text.append((754, y3 + 330, 14, "the crop from behind, up close", soft))
    x0 = 990
    text.append((x0, y3, 16, "Fix 1: her back from the player's camera, at 64 px over dark, before and after", ink))
    for i, model in enumerate((False, True)):
        shot = before[model, "back"]
        small = rs.shrink(shot, F64)
        rs.fill(page, x0 + i * 140, y3 + 26, 130, 120, rs.NIGHT)
        rs.stand(page, small, x0 + i * 140, y3 + 136, 130)
        big = np.repeat(np.repeat(small, 2, axis=0), 2, axis=1)
        rs.fill(page, x0 + 290 + i * 140, y3 + 26, 130, 190, rs.NIGHT)
        rs.stand(page, big, x0 + 290 + i * 140, y3 + 206, 130)
        text.append((x0 + i * 140, y3 + 150, 13, f"{'the model' if model else 'the sheet'}: {light_share(shot):.0%} light", soft))
    text.append((x0 + 290, y3 + 222, 13, "the same, each pixel doubled", soft))
    text.append((x0, y3 + 246, 16, "Fix 2: the crop's outline, from behind and from the player's camera", ink))
    for i, model in enumerate((False, True)):
        for c, view in enumerate(("nape", "crown")):
            sil = rs.black(rs.shrink(before[model, view], 0.27))
            rs.stand(page, sil, x0 + i * 290 + c * 140, y3 + 390, 130)
        text.append((x0 + i * 290, y3 + 398, 13, "the sheet" if not model else "the model", soft))
    # the right column: the 64 px read, the atlas, the numbers
    xr, yr = 1570, 24
    grounds = ((rs.NIGHT, "64 px, dark ground", ("game", "quarter"), False),
               (ps.DUSK, "64 px, Lantern Row's dusk, lit as dusk", ("gamedusk", "quarterdusk"), False),
               (rs.DAY, "64 px, bright ground", ("game", "quarter"), False),
               (rs.PAPER, "64 px, outline", ("game", "quarter"), True))
    for r, (ground, label, names, sil) in enumerate(grounds):
        y = yr + r * 132
        rs.fill(page, xr, y, 330, 110, ground)
        cx = xr + 4
        for name in names:
            shot = rs.shrink(shots[name], F64)
            rs.stand(page, rs.black(shot) if sil else shot, cx, y + 104, shot.shape[1])
            cx += shot.shape[1] + 6
        text.append((xr, y + 114, 12, label, soft))
    for i, kind in enumerate(("Color", "Metalness")):
        atlas = rs.load(paths[kind])
        atlas[..., 3] = 1.0
        rs.paste(page, rs.shrink(atlas, 140 / SIZE), xr + i * 150, 560)
        text.append((xr + i * 150, 704, 12, f"the {kind.lower()} map" if kind == "Color" else "metalness: the steel", soft))
    for i, line in enumerate(facts + [f"her back without the tail, at 64 px, as the maps", f"draw it: {numbers['day']:.0%} light by day, "
                                                                                         f"{numbers['dusk']:.0%} at dusk"]):
        text.append((xr, 736 + i * 21, 12, line, ink))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "kirra_model_sheet.png")
    rs.save(rs.shrink(page, 0.5), out / "kirra_model_sheet_small.png")
    return numbers


def atlas_check(paths, out):
    """The colour map as it uploads, for the content check: whole, and at 64 px on a dark and a bright ground."""
    page = rs.canvas(SIZE + 400, SIZE + 40, rs.NIGHT)
    atlas = rs.load(paths["Color"])
    atlas[..., 3] = 1.0
    rs.paste(page, atlas, 20, 20)
    small = rs.shrink(atlas, 64 / SIZE)
    rs.fill(page, SIZE + 40, 120, 104, 104, rs.DAY)
    rs.paste(page, small, SIZE + 60, 20)
    rs.paste(page, small, SIZE + 60, 140)
    rs.paste(page, rs.shrink(atlas, 300 / SIZE), SIZE + 60, 260)
    text = [(SIZE + 40, 580, 13, "Kirra_Color.png: 64 px on dark and on bright, and at 300 px", "#9A9CA8")]
    rs.paste(page, rs.text_layer(page.shape[1], page.shape[0], text), 0, 0)
    rs.save(page, out / "kirra_atlas_check.png")


def main():
    began = time.time()
    out = bl.out_dir()
    rs.OUT = ps.OUT = ks.OUT = out
    rm.APART = APART  # rook_model.split takes the pieces back by it
    before = compare(out)
    print("before and after: " + ", ".join(f"{'model' if model else 'sheet'} {light_share(before[model, 'back']):.0%} light"
                                           for model in (False, True)))
    scene = bl.reset_scene()
    joints = ks.build(scene, model=True)
    m = joints.pop("m")
    rings = rest_tail()
    made = {piece: make_blade(piece, m) for piece in BLADES}
    scarf, sag = make_scarf(rings, m)
    made.update(scarf)
    surfaces()
    groups = take_pieces(joints, made)
    hidden = total = 0
    for index, piece in enumerate(PIECES):
        h, t = rm.mark_faces(groups[piece], index)
        hidden, total = hidden + h, total + t
        for o in groups[piece]:
            o.data.transform(Matrix.Translation((APART * index, 0, 0)))
    whole = bl.join([o for piece in PIECES for o in groups[piece]], "Kirra")
    area, density = rm.unwrap(whole, SURFACES, UNLIT)
    print(f"faces {total}, unseen {hidden}; seen area {area:.1f} sq studs; {density:.0f} px per stud at {SIZE}")
    paths = rm.bake(whole, out, "Kirra", SURFACES, ks.PALETTE, GROUND, UNLIT, {}, "kirra_model.py")
    paths.pop("Emissive").unlink()
    pieces = rm.split(whole, PIECES, "Kirra")
    recipe = export(pieces, paths, out, density, rings, sag)
    body = [v.co for piece, o in pieces.items() if piece not in SCARF for v in o.data.vertices]
    tall = max(p.z for p in body)
    wide = max(p.x for p in body) - min(p.x for p in body)
    facts = [f"{recipe['tris']} triangles in {len(pieces)} pieces", f"{tall:.2f} studs to the hair's top, {wide:.2f} wide",
             f"one {SIZE} px atlas, {density:.0f} px per stud", f"the tail: {LINKS} joints, a chain from the knot,",
             f"each segment within {sag:.2f} studs of its chord", "the blades: a joint each on the Torso, at the grip",
             "maps: colour, roughness, metalness", "no glow, no normal map"]
    print("; ".join(facts))
    pivots = {**ks.PIVOTS, **chain(joints, rings)}
    numbers = review(joints, pivots, pieces, rings, paths, recipe, out, facts, before)
    atlas_check(paths, out)
    print(f"sizes {numbers.get(('square', 'size'))}, top {numbers.get(('square', 'top'))}; idle {numbers.get(('idle', 'size'))}")
    print(f"done in {time.time() - began:.0f} s")


if __name__ == "__main__":
    main()
