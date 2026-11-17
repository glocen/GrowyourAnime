"""A kit's meshes, as the upload check sees them: each mesh JSON from a handoff, grey as its own thumbnail shows it and in
its colour picture, from the front three-quarter and from above, at full size and at 64 px over dark and over bright.
Read back from the exported JSON (blcommon.export_mesh_json's frame), so the sheet shows the files Faber uploads.

Run: blender -b --factory-startup --python tools/blender/mesh_sheet.py -- <out.png> <meshes folder> <colour map> <title>
"""
import json
import sys
import textwrap
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402

SIZE, SMALL, GAP, LABEL = 300, 64, 10, 230
VIEWS = (("front three-quarter", Vector((0.55, 0.8, 0.42)).normalized()),
         ("above", Vector((0.12, 0.3, 1.0)).normalized()))
SHOTS = (("grey", 0), ("colour", 0), ("colour", 1))   # what each column shows: how it's shaded, and from which view
DARK, BRIGHT, PAGE = (0.05, 0.045, 0.07), (0.78, 0.78, 0.8), (0.075, 0.07, 0.085)
INK, SOFT = "#F2ECE2", "#B9B2C4"


def load(path: Path):
    """A mesh JSON back in Blender's frame (Roblox X, Y, Z is Blender X, Z, -Y), with its UVs (V flipped back)."""
    r = json.loads(path.read_text(encoding="utf-8"))
    p = np.array(r["p"], np.float64).reshape(-1, 3)
    f = np.array(r["f"], np.int64).reshape(-1, 9)
    t = np.array(r["t"], np.float64).reshape(-1, 2) if r.get("t") else None
    mesh = bpy.data.meshes.new(path.stem)
    mesh.from_pydata([(x, -z, y) for x, y, z in p], [], [tuple(int(i) for i in row[:3]) for row in f])
    if t is not None:
        uv = mesh.uv_layers.new(name="UV")
        for poly in mesh.polygons:
            row = f[poly.index]
            for k, loop in enumerate(poly.loop_indices):
                u, v = t[row[6 + k]]
                uv.data[loop].uv = (u, 1.0 - v)
    mesh.update()
    return mesh, len(f)


def materials(colour_map: Path):
    grey = bpy.data.materials.new("Grey")
    grey.diffuse_color = (0.6, 0.6, 0.62, 1.0)
    painted = bpy.data.materials.new("Colour")
    painted.use_nodes = True
    nodes = painted.node_tree.nodes
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(str(colour_map))
    painted.node_tree.links.new(tex.outputs["Color"], nodes["Principled BSDF"].inputs["Base Color"])
    nodes.active = tex
    return dict(grey=grey, colour=painted)


def shoot(scene, obj, view, shading, scratch: Path):
    """One ortho view, framed to the mesh's own outline from that side."""
    scene.display.shading.color_type = "MATERIAL" if shading == "grey" else "TEXTURE"
    d = VIEWS[view][1]
    rot = (-d).to_track_quat("-Z", "Y").to_matrix()
    right, up = rot.col[0], rot.col[1]
    pts = np.array([v.co[:] for v in obj.data.vertices])
    xs, ys = pts @ np.array(right[:]), pts @ np.array(up[:])
    mid = Vector(pts.mean(0))
    centre = mid + right * ((xs.max() + xs.min()) / 2 - mid.dot(right)) + up * ((ys.max() + ys.min()) / 2 - mid.dot(up))
    reach = float(np.linalg.norm(pts - np.array(mid[:]), axis=1).max())
    cam = scene.camera
    cam.data.type, cam.data.ortho_scale = "ORTHO", max(xs.max() - xs.min(), ys.max() - ys.min()) * 1.1
    cam.data.clip_start, cam.data.clip_end = 0.1, reach * 8 + 10
    cam.location, cam.rotation_euler = centre + d * (reach * 3 + 5), rot.to_euler()
    scene.render.filepath = str(scratch)
    bpy.ops.render.render(write_still=True)
    px = rs.load(scratch)
    scratch.unlink()
    return px


def over(picture, size, ground):
    small = rs.shrink(picture, size / picture.shape[1])
    back = rs.canvas(size, size, ground)
    rs.paste(back, small, 0, 0)
    return back


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    out, meshes, colour_map, title = Path(args[0]), Path(args[1]), Path(args[2]), args[3]
    manifest = meshes.parent / "manifest.json"
    notes = json.loads(manifest.read_text(encoding="utf-8"))["pieces"] if manifest.exists() else {}
    scene = bl.reset_scene()
    rs.workbench(scene, SIZE, SIZE)
    scene.display.shading.show_specular_highlight = True
    cam = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    mats = materials(colour_map)
    files = sorted(meshes.glob("*.json"))
    smalls = 4
    W = 24 + LABEL + len(SHOTS) * (SIZE + GAP) + smalls * (SMALL + 8) + 24
    H = 96 + len(files) * (SIZE + GAP) + 40
    page = rs.canvas(W, H, PAGE)
    text = [(24, 18, 24, title, INK),
            (24, 50, 13, "Each mesh read back from its JSON. Columns: grey from the front three-quarter (as its own thumbnail "
                         "shows it), in its colour picture from the front three-quarter and from above;", SOFT),
            (24, 68, 13, "then at 64 px over dark (those three) and over bright (the colour, front). The glow picture isn't "
                         "drawn.", SOFT)]
    total = 0
    for i, path in enumerate(files):
        mesh, tris = load(path)
        total += tris
        obj = bpy.data.objects.new(path.stem, mesh)
        scene.collection.objects.link(obj)
        y = 96 + i * (SIZE + GAP)
        shots = []
        for shading, view in SHOTS:
            mesh.materials.clear()
            mesh.materials.append(mats[shading])
            shots.append(shoot(scene, obj, view, shading, out.parent / f"_{path.stem}.png"))
        for k, px in enumerate(shots):
            x = 24 + LABEL + k * (SIZE + GAP)
            rs.paste(page, rs.canvas(SIZE, SIZE, DARK), x, y)
            rs.paste(page, px, x, y)
        x = 24 + LABEL + len(SHOTS) * (SIZE + GAP)
        for k, (px, ground) in enumerate(((shots[0], DARK), (shots[1], DARK), (shots[2], DARK), (shots[1], BRIGHT))):
            rs.paste(page, over(px, SMALL, ground), x + k * (SMALL + 8), y + (SIZE - SMALL) // 2)
        size = np.array([v.co[:] for v in mesh.vertices])
        size = size.max(0) - size.min(0)
        text.append((24, y + 6, 15, path.stem, INK))
        text.append((24, y + 28, 12, f"{tris:,} triangles", SOFT))
        text.append((24, y + 44, 12, f"{size[0]:.1f} by {size[1]:.1f} by {size[2]:.1f} studs", SOFT))
        for j, line in enumerate(textwrap.wrap(notes.get(path.stem, {}).get("note", ""), 34)[:12]):
            text.append((24, y + 66 + 14 * j, 11, line, SOFT))
        bpy.data.objects.remove(obj)
        bpy.data.meshes.remove(mesh)
    text.append((24, H - 30, 13, f"{len(files)} meshes, {total:,} triangles in all.", INK))
    rs.OUT = out.parent   # where the text layer draws its scratch
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out)
    print(f"wrote {out} {W}x{H}: {len(files)} meshes, {total} triangles")


if __name__ == "__main__":
    main()
