"""The elite's contact sheet (AR2, section 5, condition 9; section 6's 16/6 check, condition 2): the Brawler elite
with its second mask on, the copy without ties where the game puts it, in the nine delivered clips, from the player's
camera, at 64 px on dark and bright, with the ordinary Shade beside it where the 16/6 check asks.

blender.exe -b --factory-startup --python tools/blender/shade_elite_contact.py -- <out_dir>

Drawn on the baked model (shade_model.py's blend) riding the rig (shade_clips.build), lit as the maps draw in Eevee: the
body's glow in Strength's tint at the game's strength and the masks' in their own warm white at theirs (Config.Shades,
written here as TINT, BODY and MASK). Eevee has neither the engine's tone map nor its bloom, so how red bloom hazes onto
the ground stays a look in the engine. Each clip's widest frame is the one whose figure is widest across the player's
camera. Every frame of every clip is measured too: how near the second mask comes to the coat, the other sleeve and the
first mask (signed, so a point inside a piece reads below zero).

Writes shade_elite_contact.png to <out_dir>. Needs shade_model.py's output in shade_clips.MODEL and the handoff's clips
and Shade_MaskBrawlerBare.json.
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import r6anim as r6  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_clips as sc  # noqa: E402
import shade_elite as se  # noqa: E402
import shade_elite_bare as eb  # noqa: E402
import shade_model as sm  # noqa: E402

HANDOFF = se.RECIPE.parent
# condition 9's four first, then the rest in the delivered order
CLIPS = ("Guard", "AttackLeft", "HitLeft", "Burst", "Idle", "Walk", "Attack", "Lunge", "Hit")
GAP = 400                     # frames between clips on the one timeline
VIEW = (336.0, 18.0, 13.0)    # the player's camera on a Shade that faces the lead: its front and its left (body_camera)
SUN = (540 - VIEW[0]) % 360   # the same heading in rook_sheet's measure, for the sun over the camera's left shoulder
FOV, PX = 38.0, 640
TINT, BODY, MASK = "#E80000", 16.0, 6.0  # Config.Shades: Strength's glow tint, the body's strength, a mask's
STUD = PX / (2 * VIEW[2] * math.tan(math.radians(FOV / 2)))  # pixels a stud at the body, in a render
F64 = 64 / (5 * STUD)         # a 5 stud body 64 px tall
BIG = 0.5
# the frames condition 9 names in the four first: the guard braced (its left sleeve level under the first mask), the
# left swing's hit, the blow from the left, the last frame before the burst
NAMED = {"Guard": (44, "braced"), "AttackLeft": (30, "Hit"), "HitLeft": (3, "struck"), "Burst": (27, "Burst")}
# the 16/6 check's condition 2: the ordinary Shade and the elite side by side. None is the clip's widest frame.
SIDE_BY_SIDE = (("HitLeft", None), ("Burst", 20), ("Burst", 27))
NEAR = ("Torso", "RightArm", "Mask")  # what the second mask may not sink into: the coat, the other sleeve, the first mask
SEEN = ("Seen: in AttackLeft the second mask crosses the first from 26 to 31, round the Hit, and the coat at 26: at 64 px",
        "the two masks are one pale shape. Every other clip clears. The game plays Attack and AttackLeft in turn, so it shows.",
        "Moving the mask down or round the arm doesn't clear AttackLeft without crossing the Guard or the sleeve, or turning side-on.")


def key_clips(rig):
    """Every clip on its own stretch of the timeline: {clip: (start, last frame)}."""
    spans = {}
    for i, clip in enumerate(CLIPS):
        data = json.loads((HANDOFF / "clips" / f"Shade_{clip}.json").read_text())
        start, last = i * GAP, 0
        for frame in data["Frames"]:
            f = round(frame["T"] * data["Fps"])
            last = max(last, f)
            for part, pose in frame["Poses"].items():
                joint = rig.joints.get(part)
                if joint is None:
                    continue
                joint.matrix_basis = r6.to_blender(r6.cframe(pose))
                joint.keyframe_insert("location", frame=start + f)
                joint.keyframe_insert("rotation_quaternion", frame=start + f)
        spans[clip] = (start, last)
    return spans


def glow(objects):
    """The game's glow: the body in Strength's tint at its strength, every mask in its own tint at a mask's."""
    for material in {slot.material for o in objects for slot in o.material_slots}:
        nodes = material.node_tree.nodes
        tint = next(n for n in nodes if n.bl_idname == "ShaderNodeMix" and n.blend_type == "MULTIPLY")
        strength = next(n for n in nodes if n.bl_idname == "ShaderNodeMath" and n.operation == "MULTIPLY")
        mask = "Mask" in material.name
        tint.inputs[7].default_value = rs.srgb(sm.MASK_TINT if mask else TINT)
        strength.inputs[1].default_value = MASK if mask else BODY
        print(f"{material.name}: {sm.MASK_TINT if mask else TINT} at {MASK if mask else BODY}")


def across(rig, frame):
    """The player's camera's horizontal right, in Blender's frame, as the body stands at `frame`."""
    bpy.context.scene.frame_set(frame)
    root = r6.to_roblox(rig.root.matrix_world)
    look = Vector((-root[0][2], -root[1][2], -root[2][2]))
    side = look.cross(Vector((0, 1, 0))).normalized()
    a = math.radians(VIEW[0])
    toward_eye = look * math.cos(a) + side * math.sin(a)
    return np.array(r6.point_to_blender(toward_eye.cross(Vector((0, 1, 0))).normalized()))


def points(obj):
    n = len(obj.data.vertices)
    co = np.empty(n * 3, dtype=np.float64)
    obj.data.vertices.foreach_get("co", co)
    return np.c_[co.reshape(n, 3), np.ones(n)]


def measure(scene, rig, spans, shown, copy, near):
    """Per clip: the widest frame across the player's camera; for each piece in `near`, the frames where the second
    mask's triangles cross the piece's (exact, triangle against triangle) and the nearest any point of the mask comes
    to the piece's surface, with its frame. A coat and a sleeve are open shells, so nearness has no inside or outside:
    the crossing test is what says sunk."""
    local = {o.name: points(o) for o in shown}
    polys = {o.name: [tuple(p.vertices) for p in o.data.polygons] for o in (copy, *near.values())}

    def tree(o):
        m = o.matrix_world
        return BVHTree.FromPolygons([m @ v.co for v in o.data.vertices], polys[o.name])

    found = {}
    for clip, (start, last) in spans.items():
        right = across(rig, start)
        widest = (0.0, start)
        gaps = {name: (math.inf, start) for name in near}
        crossed = {name: [] for name in near}
        for f in range(start, start + last + 1):
            scene.frame_set(f)
            xs = np.concatenate([(local[o.name] @ np.array(o.matrix_world).T)[:, :3] @ right for o in shown])
            widest = max(widest, (float(xs.max() - xs.min()), f))
            mask = tree(copy)
            world = [copy.matrix_world @ v.co for v in copy.data.vertices]
            for name, o in near.items():
                piece = tree(o)
                if mask.overlap(piece):
                    crossed[name].append(f - start)
                gap = min(piece.find_nearest(p)[3] for p in world)
                if gap < gaps[name][0]:
                    gaps[name] = (gap, f)
        found[clip] = {"widest": (widest[1] - start, round(widest[0], 2)),
                       "near": {name: (round(g, 3), f - start) for name, (g, f) in gaps.items()},
                       "crossed": crossed}
        print(f"{clip}: widest at {widest[1] - start} ({widest[0]:.2f} studs across the camera); nearest "
              + ", ".join(f"{name} {g:.3f} at {f - start}" for name, (g, f) in gaps.items())
              + "; crossing " + (", ".join(f"{n} at {c}" for n, c in crossed.items() if c) or "none"))
    return found


def shot(scene, rig, frame, dusk, name, out):
    rm.eevee(scene, PX, PX)
    sm.lighting(scene, SUN, dusk)
    scene.render.use_stamp = False
    scene.camera = r6.body_camera(scene, rig, frame, VIEW[0], VIEW[1], distance=VIEW[2], fov=FOV, name=name)
    scene.frame_set(frame)
    path = out / f"_{name}.png"
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    picture = rs.load(path)
    path.unlink()
    return picture


def main():
    out = bl.out_dir()
    rs.OUT = out
    recipe = json.loads(se.RECIPE.read_text(encoding="utf-8"))
    scene, rig, undress, wear, feet = sc.build()
    wear("Brawler")
    bpy.context.view_layer.update()
    first = bpy.data.objects[recipe["masks"]["Brawler"]["name"]]
    bare = json.loads((HANDOFF / "Shade_MaskBrawlerBare.json").read_text())
    copy = eb.mesh_object("EliteBrawlerBare", bare, first.material_slots[0].material)
    eb.wear(rig, copy, recipe["elite"]["masks"]["Brawler"])
    bpy.data.objects["Floor"].hide_render = True
    body = [bpy.data.objects[p["name"]] for p in recipe["pieces"]]
    glow(body + [first])
    spans = key_clips(rig)
    by_part = {p["name"]: p["on"] for p in recipe["pieces"]}
    near = {"Torso": next(o for o in body if by_part[o.name] == "Torso"),
            "RightArm": next(o for o in body if by_part[o.name] == "Right Arm"), "Mask": first}
    found = measure(scene, rig, spans, body + [first, copy], copy, near)

    shots = {}

    def picture(clip, frame, dusk, worn=True):
        """The elite (the second mask on) or the ordinary Shade, at `frame` of `clip`, rendered once."""
        if (clip, frame, dusk, worn) not in shots:
            copy.hide_render = not worn
            shots[clip, frame, dusk, worn] = shot(scene, rig, spans[clip][0] + frame, dusk,
                                                  f"{clip}{frame}_{int(dusk)}{int(worn)}", out)
            copy.hide_render = False
        return shots[clip, frame, dusk, worn]

    # band A's columns: each clip's widest frame, and for the four first the frame condition 9 names
    row = []
    for clip in CLIPS:
        row.append((clip, found[clip]["widest"][0], "widest"))
        if clip in NAMED and NAMED[clip][0] != found[clip]["widest"][0]:
            row.append((clip, *NAMED[clip]))
    # band B: the four first's named frame, then where the second mask comes nearest anything, or first crosses it
    close = []
    for clip in CLIPS[:4]:
        close.append((clip, *NAMED[clip]))
        crossings = sorted(f for c in found[clip]["crossed"].values() for f in c)
        gap, at = min(found[clip]["near"].values())
        what, at = ("crosses", crossings[0]) if crossings else (f"nearest, {gap:.2f}", at)
        if at != NAMED[clip][0]:
            close.append((clip, at, what))

    W, H = 2400, 1640
    ink, soft, pale = "#1E1B22", "#6A655E", "#B9B4C6"
    page = rs.canvas(W, H, rs.PAPER)
    text = [(40, 26, 40, "THE ELITE, CONTACT SHEET", ink),
            (40, 80, 17, f"AR2, section 5, condition 9. The Brawler elite ({se.SCALE:g}) with its second mask, the copy without ties where the game "
                         f"puts it, from the player's camera. Body {TINT} at {BODY:g}, masks {sm.MASK_TINT} at {MASK:g}, lit in Eevee: no engine "
                         "tone map, no bloom.", soft)]
    # band A: at 64 px, dusk on dark, day on bright
    x0, y0, col = 40, 150, 120
    text.append((x0, y0 - 34, 16, "Each clip at its widest, and the frame condition 9 names, at 64 px (an ordinary Shade's 5 studs; the elite stands 1.35 of that)", soft))
    for r, (dusk, ground) in enumerate(((True, rs.NIGHT), (False, rs.DAY))):
        y = y0 + r * 132
        rs.fill(page, x0, y, col * len(row), 128, ground)
        for c, (clip, frame, _) in enumerate(row):
            rs.stand(page, rs.shrink(picture(clip, frame, dusk), F64 * se.SCALE), x0 + c * col, y + 120, col)
    for c, (clip, frame, label) in enumerate(row):
        first4 = clip in NAMED
        text.append((x0 + c * col + 6, y0 + 268, 13, clip, ink if first4 else soft))
        text.append((x0 + c * col + 6, y0 + 286, 13, f"{frame}, {label}", ink if first4 else soft))
    # band A, right: the ordinary Shade and the elite side by side
    x1, pc = x0 + col * len(row) + 40, 112
    text.append((x1, y0 - 34, 16, "Beside the ordinary Shade (16/6 check, condition 2)", soft))
    for c, (clip, frame) in enumerate(SIDE_BY_SIDE):
        frame = found[clip]["widest"][0] if frame is None else frame
        for r, dusk in enumerate((True, False)):
            y = y0 + r * 132
            rs.fill(page, x1 + c * 2 * pc, y, 2 * pc, 128, rs.NIGHT if dusk else rs.DAY)
            rs.stand(page, rs.shrink(picture(clip, frame, dusk, worn=False), F64), x1 + c * 2 * pc, y + 120, pc)
            rs.stand(page, rs.shrink(picture(clip, frame, dusk), F64 * se.SCALE), x1 + c * 2 * pc + pc - 14, y + 120, pc)
        text.append((x1 + c * 2 * pc + 6, y0 + 268, 13, f"{clip} {frame}", ink))
    text.append((x1, y0 + 296, 13, "Each pair: the ordinary Shade, then the elite.", soft))
    text.append((x1, y0 + 314, 13, "The Shade has no fallen pose: Burst 27 is its last,", soft))
    text.append((x1, y0 + 332, 13, "standing, and the game hides it there.", soft))

    # band B: the four first, larger, at dusk
    y1, bc = 560, 236
    text.append((x0, y1 - 30, 16, "Guard, AttackLeft, HitLeft, Burst, larger, at dusk: the frame condition 9 names, then where the second mask comes nearest the coat, the other sleeve or the first mask", soft))
    rs.fill(page, x0, y1, bc * len(close), 330, rs.NIGHT)
    for c, (clip, frame, label) in enumerate(close):
        rs.stand(page, rs.shrink(picture(clip, frame, True), BIG * se.SCALE), x0 + c * bc, y1 + 318, bc)
        text.append((x0 + c * bc + 10, y1 + 8, 14, f"{clip} {frame}, {label}", pale))
    # band C: the nine widest, larger, at dusk
    y2 = 960
    text.append((x0, y2 - 30, 16, "The nine at their widest, larger, at dusk", soft))
    rs.fill(page, x0, y2, bc * len(CLIPS), 330, rs.NIGHT)
    for c, clip in enumerate(CLIPS):
        frame = found[clip]["widest"][0]
        rs.stand(page, rs.shrink(picture(clip, frame, True), BIG * se.SCALE), x0 + c * bc, y2 + 318, bc)
        text.append((x0 + c * bc + 10, y2 + 8, 14, f"{clip} {frame}", pale))
    # the measures
    y3 = 1340
    text.append((x0, y3, 16, "Every frame of every clip, at an ordinary Shade's size: the second mask's nearest approach to the coat, the other sleeve and the first mask "
                             "(studs, at its frame), and any frame where its triangles cross theirs", ink))
    for i, clip in enumerate(CLIPS):
        near_, crossed = found[clip]["near"], found[clip]["crossed"]
        crossing = "; crosses " + ", ".join(f"{n} at {c[0]} to {c[-1]}" for n, c in crossed.items() if c) if any(crossed.values()) else "; crosses nothing"
        line = (f"{clip}: coat {near_['Torso'][0]:.2f} at {near_['Torso'][1]}, sleeve {near_['RightArm'][0]:.2f} at {near_['RightArm'][1]}, "
                f"first mask {near_['Mask'][0]:.2f} at {near_['Mask'][1]}{crossing}")
        text.append((x0 + (i // 5) * 1180, y3 + 34 + (i % 5) * 24, 14, line, ink if clip in NAMED else soft))
    for i, line in enumerate(SEEN):
        text.append((x0 + 1180, y3 + 34 + (4 + i) * 24, 14, line, ink))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "shade_elite_contact.png")
    (out / "shade_elite_contact.json").write_text(json.dumps(found, indent=1))
    print(f"wrote {out / 'shade_elite_contact.png'}")

if __name__ == "__main__":
    main()
