"""The elite's second mask without its ties (AR2, section 6): the mask's mesh with its strings, knot and tails cut
away, and a look at it on the Left Arm where the game puts it, in the clips the engine showed the ties in.

blender.exe -b --factory-startup --python tools/blender/shade_elite_bare.py -- <out_dir> [write]

The second mask is the Shade's own mask again, welded to the Left Arm at 0.6 (shade_elite.py). Its ties were meant to
end inside the sleeve, but the sleeve is too narrow for them: in the engine they stand out of it as pale rods, from
below and from behind (AR2, section 6). A mask on an arm needs no ties, so the copy is the same mesh without them: the
same triangles, normals and UVs, so it wears the same surface and the same three maps. Only its centre moves, because a
published mesh is centred on its own box, and shade_elite.py's placement follows it.

Writes to <out_dir>: Shade_Mask<Kind>Bare.json for each kind in KINDS, and shade_elite_bare.png: close on the arm in
Idle and Guard, from below and from behind as the builder looked, the copy with its ties above and without below, and
the Guard from the player's camera. Needs shade_model.py's output in shade_clips.MODEL. `write` copies the meshes into
build/handoff/Shade/ and writes the recipe's `elite` again (shade_elite.write).
"""
import json
import math
import shutil
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import r6anim as r6  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_clips as sc  # noqa: E402
import shade_elite as se  # noqa: E402

HANDOFF = se.RECIPE.parent
KINDS = ("Brawler",)  # the elites that go in: the others wait on their own sheet and check (AR2, section 5, condition 5)
BEHIND = -0.5         # Roblox z past which a piece reaches behind the mask's back (-0.73): only the ties go there
TIES = 5              # two strings, a knot and the knot's two tails, each its own island
# the builder's looks: idle and the guard braced, close on the arm from below and from behind; then the player's camera
# (degrees from the body's front, 90 its right, so 270 its left; degrees up; studs away)
SHOTS = [("Idle", 0, "below, front left", (300, -40, 4.5)), ("Idle", 0, "below, left", (250, -45, 4.5)),
         ("Idle", 90, "behind", (200, 6, 5.0)),
         ("Guard", 44, "below, front left", (300, -40, 4.5)), ("Guard", 44, "below, left", (250, -45, 4.5)),
         ("Guard", 44, "behind", (200, 6, 5.0)), ("Guard", 44, "behind, left", (235, 10, 5.0)),
         ("Guard", 44, "the player's camera", None)]
START = {"Idle": 0, "Guard": 1000}


def bare(kind, out):
    """The mask's mesh less every island of points that reaches behind its back. Each piece was its own object when
    the mask was built, so the ties are islands of their own here."""
    mesh = json.loads((HANDOFF / f"Shade_Mask{kind}.json").read_text())
    c, p, n, t, f = mesh["c"], mesh["p"], mesh["n"], mesh["t"], mesh["f"]
    parent = list(range(len(p) // 3))

    def root(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    tris = [f[i:i + 9] for i in range(0, len(f), 9)]
    for tri in tris:
        for v in tri[1:3]:
            parent[root(v)] = root(tri[0])
    behind = {root(i) for i in range(len(parent)) if p[3 * i + 2] + c[2] > BEHIND}
    if len(behind) != TIES:
        raise SystemExit(f"{kind}: {len(behind)} islands behind the mask, not the ties' {TIES}")
    keep = [tri for tri in tris if root(tri[0]) not in behind]

    def reindex(slots, data, stride):
        used = sorted({tri[k] for tri in keep for k in slots})
        return {old: i for i, old in enumerate(used)}, [x for old in used for x in data[old * stride:(old + 1) * stride]]

    to_p, points = reindex(range(3), p, 3)
    to_n, normals = reindex(range(3, 6), n, 3)
    to_t, uvs = reindex(range(6, 9), t, 2)
    model = [points[i] + c[i % 3] for i in range(len(points))]  # where each point is on the face, in the model
    low = [min(model[a::3]) for a in range(3)]
    high = [max(model[a::3]) for a in range(3)]
    centre = [(lo + hi) / 2 for lo, hi in zip(low, high)]
    record = {"c": [round(x, 5) for x in centre],
              "p": [round(model[i] - centre[i % 3], 5) for i in range(len(model))], "n": normals, "t": uvs,
              "f": [x for tri in keep for x in [to_p[v] for v in tri[0:3]] + [to_n[v] for v in tri[3:6]] + [to_t[v] for v in tri[6:9]]]}
    path = out / f"Shade_Mask{kind}Bare.json"
    path.write_text(json.dumps(record, separators=(",", ":")))
    size = [round(hi - lo, 3) for lo, hi in zip(low, high)]
    print(f"{path.name}: {len(keep)} of {len(tris)} triangles, {len(tris) - len(keep)} cut in {len(behind)} islands; "
          f"{size} studs, centre {record['c']} (the mask's was {c})")
    return record, {old: new for old, new in to_p.items()}


def mesh_object(name, record, material):
    """A delivered mesh in Blender, in its part's own frame, with its UVs."""
    p, t = record["p"], record["t"]
    tris = [record["f"][i:i + 9] for i in range(0, len(record["f"]), 9)]
    data = bpy.data.meshes.new(name)
    data.from_pydata([tuple(r6.point_to_blender(p[i:i + 3])) for i in range(0, len(p), 3)], [], [tuple(tri[:3]) for tri in tris])
    uv = data.uv_layers.new(name="UVMap")
    for poly, tri in zip(data.polygons, tris):
        for loop, k in zip(poly.loop_indices, tri[6:9]):
            uv.data[loop].uv = (t[2 * k], 1 - t[2 * k + 1])
    data.materials.append(material)
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def wear(rig, obj, at):
    """As the game places it (tools/studio/Models/Shade.luau): CFrame.fromMatrix(centre, right, up, -facing) in the
    model's frame, the part at shade_elite.SMALL of its size, welded to the Left Arm as the rig stands at rest."""
    x, y, z = Vector(at["right"]), Vector(at["up"]), -Vector(at["facing"])
    frame = Matrix(((x[0], y[0], z[0], at["centre"][0]), (x[1], y[1], z[1], at["centre"][1]),
                    (x[2], y[2], z[2], at["centre"][2]), (0, 0, 0, 1)))
    arm = rig.parts["Left Arm"]
    obj.parent = arm
    obj.matrix_parent_inverse = arm.matrix_world.inverted()
    obj.matrix_basis = r6.to_blender(frame) @ Matrix.Scale(se.SMALL, 4)


def key(rig, clip):
    data = json.loads((HANDOFF / "clips" / f"Shade_{clip}.json").read_text())
    for frame in data["Frames"]:
        f = START[clip] + round(frame["T"] * data["Fps"])
        for part, pose in frame["Poses"].items():
            joint = rig.joints.get(part)
            if joint is None:
                continue
            joint.matrix_basis = r6.to_blender(r6.cframe(pose))
            joint.keyframe_insert("location", frame=f)
            joint.keyframe_insert("rotation_quaternion", frame=f)


def near(scene, rig, obj, frame, azimuth, elevation, distance, name):
    """A camera on the second mask as it is at `frame`, from `azimuth` degrees round the body's front."""
    scene.frame_set(frame)
    root = r6.to_roblox(rig.root.matrix_world)
    look = Vector((-root[0][2], -root[1][2], -root[2][2]))
    side = look.cross(Vector((0, 1, 0))).normalized()
    a, e = math.radians(azimuth), math.radians(elevation)
    focus = r6.point_to_roblox(obj.matrix_world.translation)
    eye = focus + (look * math.cos(a) + side * math.sin(a)) * distance * math.cos(e) + Vector((0, distance * math.sin(e), 0))
    return r6.fixed_camera(scene, eye, focus, 40.0, name)


def main():
    out = bl.out_dir()
    rs.OUT = out
    write = "write" in sys.argv[sys.argv.index("--") + 2:]
    recipe = json.loads(se.RECIPE.read_text(encoding="utf-8"))
    made = {kind: bare(kind, out) for kind in KINDS}

    scene, rig, undress, dress, feet = sc.build()
    bpy.context.view_layer.update()
    costume = bpy.data.objects[recipe["masks"]["Brawler"]["name"]]
    material = costume.material_slots[0].material
    copies = {}
    for kind, (record, to_p) in made.items():
        whole = json.loads((HANDOFF / f"Shade_Mask{kind}.json").read_text())
        tied, cut = mesh_object(f"Elite{kind}Tied", whole, material), mesh_object(f"Elite{kind}Bare", record, material)
        wear(rig, tied, se.placement(kind, whole["c"]))          # the whole mask, ties and all, on the same points
        wear(rig, cut, se.placement(kind, record["c"]))          # the copy, where write() will put it
        bpy.context.view_layer.update()
        # the copy must sit exactly where the same points sat on the whole mask
        drift = max((cut.matrix_world @ cut.data.vertices[new].co - tied.matrix_world @ tied.data.vertices[old].co).length
                    for old, new in to_p.items())
        print(f"{kind}: the copy's points against the whole mask's, at most {drift:.5f} studs apart")
        copies[kind] = (tied, cut)
    for clip in START:
        key(rig, clip)

    tied, cut = copies["Brawler"]
    shots = []
    for i, (clip, frame, label, view) in enumerate(SHOTS):
        f = START[clip] + frame
        if view is None:
            cam = r6.body_camera(scene, rig, f, 336.0, 18.0, distance=13.0, name=f"player {i}")
        else:
            cam = near(scene, rig, cut, f, *view, f"near {i}")
        shots.append((cam, f, f"{clip} {frame}, {label}"))
    scene.render.resolution_x, scene.render.resolution_y = 300, 300
    rows = []
    for name, shown in (("tied", tied), ("bare", cut)):
        tied.hide_render, cut.hide_render = shown is not tied, shown is not cut
        path = r6.render_shots(scene, [(cam, f, f"{name}: {label}") for cam, f, label in shots],
                               out / f"_{name}.png", columns=len(shots))
        rows.append(rs.load(path))
        Path(path).unlink()
    sheet = np.concatenate(rows, axis=0)
    sheet[..., 3] = 1.0
    rs.save(sheet, out / "shade_elite_bare.png")
    print(f"wrote {out / 'shade_elite_bare.png'}: with its ties above, the copy below")

    if write:
        for kind in KINDS:
            shutil.copyfile(out / f"Shade_Mask{kind}Bare.json", HANDOFF / f"Shade_Mask{kind}Bare.json")
        se.write()


if __name__ == "__main__":
    main()
