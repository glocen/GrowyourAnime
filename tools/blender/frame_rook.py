"""AR62: Rook for the style frame's stand, in the game's light, with AR64's hair as it stands (take R, solid, accent `split`: RP, round 43).

The game's sun and sky (hard_ember: SUN, SUN_ENERGY, FILL, FILL_STRENGTH), the sun laid over the camera's left shoulder as
every stage does, so the face is lit. The body turned a third away, the head turned back to the player (the lead card's
pose). No cast shadows, as a ViewportFrame draws a figure on a screen. One transparent picture cut to the figure's own
pixels, to be laid on the frame's stand.

    blender -b --factory-startup --python tools/blender/frame_rook.py -- <out_dir> [key]

Writes <out_dir>/rook_stand.png, the whole figure, and prints its pixels per stud and the floor's row.
"""
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import anime_make as am  # noqa: E402
import blcommon as bl  # noqa: E402
import hair_ways as hw  # noqa: E402
import hard_ember as he  # noqa: E402
import rook_make_takes as rt  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402

TURN = 34.0                         # degrees the body turns from the player, his right shoulder forward
HEAD = 16.0                         # how far the head turns back toward the player
SUN_SIDE, SUN_UP = 30.0, 40.0       # the sun this far round to the camera's left, and up
PX, SPAN, MIDDLE, ELEVATION = (1600, 2000), 8.0, 2.8, 3.0   # the render, studs up it, its middle's height, the view's tilt


def game_light(scene, azimuth):
    sun = bpy.data.objects.get("Sun")
    if sun is None:
        sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
        scene.collection.objects.link(sun)
    a, e = math.radians(azimuth - SUN_SIDE), math.radians(SUN_UP)
    offset = Vector((math.cos(e) * math.sin(a), -math.cos(e) * math.cos(a), math.sin(e)))
    sun.rotation_euler = (-offset).to_track_quat("-Z", "Y").to_euler()
    sun.data.energy, sun.data.color, sun.data.angle = he.SUN_ENERGY, rs.srgb(he.SUN)[:3], math.radians(3.0)
    background = scene.world.node_tree.nodes["Background"]
    background.inputs["Color"].default_value = rs.srgb(he.FILL)
    background.inputs["Strength"].default_value = he.FILL_STRENGTH


def main():
    rest = sys.argv[sys.argv.index("--") + 1:]
    out = bl.out_dir()   # absolute: Blender writes a relative path from the drive's root
    key = rest[1] if len(rest) > 1 else "RP"
    rt.TAKES = hw.WHO_["rook"]["takes"]
    scene = bl.reset_scene()
    scene.world = bpy.data.worlds.new("Frame")
    j = rt.wt.rig(scene)
    am.PICTURES.clear()
    am.GLOWS.clear()
    (out / "tex").mkdir(exist_ok=True)
    rt.TAKES[key](j, out / "tex")
    for joint in j.values():   # the rig's rest: rook_sheet's poses were written for the old rig and lift these arms
        joint.rotation_quaternion = (1, 0, 0, 0)
    j["root"].location = rt.wt.PIVOTS["root"]
    yaw = -math.radians(HEAD)
    j["neck"].rotation_quaternion = (Matrix.Rotation(yaw, 3, "Z") @ Matrix.Rotation(math.radians(4), 3, "X")).to_quaternion()
    bpy.context.view_layer.update()
    for o in scene.objects:
        if o.type == "MESH":
            o.visible_shadow = False
    azimuth = 180.0 - TURN
    rm.eevee(scene, *PX)
    try:
        scene.eevee.taa_render_samples = 64
    except AttributeError:
        pass
    game_light(scene, azimuth)
    full = rs.shoot(scene, out / "rook_wide.png", azimuth, ELEVATION, (0.0, 0.0, MIDDLE), SPAN)
    rows, cols = np.nonzero(full[..., 3] > 0.02)
    m = 12
    top, bottom, left, right = rows.min() - m, rows.max() + m, cols.min() - m, cols.max() + m
    rs.save(full[top:bottom + 1, left:right + 1], out / "rook_stand.png")
    (out / "rook_wide.png").unlink()
    per_stud = PX[1] / SPAN
    floor = PX[1] / 2 + MIDDLE * per_stud * math.cos(math.radians(ELEVATION)) - top
    print(f"frame_rook: wrote rook_stand.png, {right - left + 1} x {bottom - top + 1}, {per_stud:.0f} px a stud, the floor's row {floor:.0f}")


if __name__ == "__main__":
    main()
