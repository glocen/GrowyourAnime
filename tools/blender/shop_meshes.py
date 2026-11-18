"""AR38's mesh sheet, for the content check before upload: each of the Void Shop's three meshes alone, untextured, at
full size and at 64 px, on dark (docs/asset-requests.md, AR38, "Content check").

The pieces are the Strip kit's own (strip_kit.py: VoidShop, VoidShopMinute, VoidShopCrown), built as the export
builds them and given one plain grey, so only the form shows: no atlas, no glow, no light of its own. Workbench, no
GPU turn, and the kit's pictures are never painted, so it's a light run.

    blender -b --factory-startup --python tools/blender/shop_meshes.py -- <abs out>

Writes <out>/shop_meshes.png: a row a mesh, from its front and from three quarters, each at full size and at 64 px.
"""
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import strip_kit as strip  # noqa: E402

bl, rs = strip.bl, strip.rs

NAMES = ("VoidShop", "VoidShopMinute", "VoidShopCrown")
VIEWS = (("from its front", 0, 8), ("from three quarters", 35, 22))   # azimuth 0 looks at the Shop's front
BIG, SMALL = 440, 64
DARK = (0.04, 0.04, 0.05)
CLAY = (0.62, 0.62, 0.66, 1.0)


def shots(out: Path):
    """Each mesh from each view, as pictures on nothing."""
    scene = bl.reset_scene()
    clay = bpy.data.materials.new("Clay")
    clay.diffuse_color = CLAY
    rs.workbench(scene, BIG, BIG)
    made = {}
    for name in NAMES:
        piece = strip.build(name)
        obj = bpy.data.objects.new(name, piece.mesh.whole().to_object(name, clay))   # to_object gives the mesh data
        scene.collection.objects.link(obj)
        corners = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
        low = Vector(min(c[i] for c in corners) for i in range(3))
        high = Vector(max(c[i] for c in corners) for i in range(3))
        span = (high - low).length * 1.04
        made[name] = dict(size=tuple(round(v, 1) for v in high - low), faces=len(obj.data.polygons), views=[])
        for _, azimuth, elevation in VIEWS:
            path = out / f"_{name}_{azimuth}.png"
            made[name]["views"].append(rs.shoot(scene, path, azimuth, elevation, (low + high) / 2, span))
            path.unlink()
        obj.hide_render = True
    return made


def sheet(out: Path):
    rs.OUT = out
    made = shots(out)
    pad, head, label = 16, 44, 26
    tile = BIG + pad + SMALL
    row = label + BIG + pad
    board = rs.canvas(pad + len(VIEWS) * (tile + pad) + 64, head + len(NAMES) * row, DARK)   # + room for the last label
    words = [(pad, 14, 17, "AR38, the Void Shop: its three meshes alone, untextured, at full size and at 64 px", "#E8E6F0")]
    for j, name in enumerate(NAMES):
        y = head + j * row
        facts = made[name]
        w, d, h = facts["size"]
        words.append((pad, y + 4, 13, f"{name}: {w:g} by {d:g} by {h:g} studs, {facts['faces']} faces", "#B8B4C8"))
        for i, ((what, _, _), shot) in enumerate(zip(VIEWS, facts["views"])):
            x = pad + i * (tile + pad)
            rs.paste(board, shot, x, y + label)
            rs.paste(board, rs.shrink(shot, SMALL / BIG), x + BIG + pad, y + label + BIG - SMALL)
            words.append((x + BIG + pad, y + label + BIG - SMALL - 18, 11, what, "#8C88A0"))
    rs.paste(board, rs.text_layer(board.shape[1], board.shape[0], words), 0, 0)
    rs.save(board, out / "shop_meshes.png")
    print("AR38: the mesh sheet is written,", {k: (v["size"], v["faces"]) for k, v in made.items()})


if __name__ == "__main__":
    sheet(bl.out_dir())
