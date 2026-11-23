"""The elite's contact sheet (AR2, section 5, condition 9; section 6's 16/6 check, condition 2): the Brawler elite
with its second mask on, the copy without ties where the game puts it, in the clips an elite plays, from the player's
camera, at 64 px on dark and bright, with the ordinary Shade beside it where the 16/6 check asks.

blender.exe -b --factory-startup --python tools/blender/shade_elite_contact.py -- <out_dir> [Kind [folder ...]]

Kind is Brawler (the default), Guard or Dasher (AR57: SETS). A folder is searched before the handoff for a clip or a
second mask, so a trial is measured before it's delivered. The Brawler's sheet is shade_elite_contact.png, another
kind's shade_elite_contact_<Kind>.png.

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
# the clips an elite plays: condition 9's four first, its swing being Attack every time, never AttackLeft (research's
# pick, AR2 section 10: in AttackLeft the second mask cuts into the first), then the rest in the delivered order

GAP = 400                     # frames between clips on the one timeline
VIEW = (336.0, 18.0, 13.0)    # the player's camera on a Shade that faces the lead: its front and its left (body_camera)
SUN = (540 - VIEW[0]) % 360   # the same heading in rook_sheet's measure, for the sun over the camera's left shoulder
FOV, PX = 38.0, 640
TINT, BODY, MASK = "#E80000", 16.0, 6.0  # Config.Shades: Strength's glow tint (the Brawler's), the body's strength, a mask's
STUD = PX / (2 * VIEW[2] * math.tan(math.radians(FOV / 2)))  # pixels a stud at the body, in a render
F64 = 64 / (5 * STUD)         # a 5 stud body 64 px tall
BIG = 0.5
# the frames condition 9 names in the four first: the guard braced (its left sleeve level under the first mask), the
# left swing's hit, the blow from the left, the last frame before the burst

# the 16/6 check's condition 2: the ordinary Shade and the elite side by side. None is the clip's widest frame.

# what the second mask may not sink into: the coat, the other sleeve, the first mask, and either leg (a low crouch
# brings the thighs up to the sleeves: AR57's check)
NEAR = ("Torso", "RightArm", "Mask", "LeftLeg", "RightLeg")
# An elite's kind: its stretch's colour, the clips it plays (the four the sheet shows larger first), the frame the sheet
# names in each of those four, the pairs shown beside the ordinary Shade (its clip, the elite's, the frame: None is the
# widest), and what was seen.
SETS = {
    "Brawler": dict(type="Red", clips=("Guard", "Attack", "HitLeft", "Burst", "Idle", "Walk", "Lunge", "Hit"),
                    named={"Guard": (44, "braced"), "Attack": (30, "Hit"), "HitLeft": (3, "struck"), "Burst": (27, "Burst")},
                    side=(("HitLeft", "HitLeft", None), ("Burst", "Burst", 20), ("Burst", "Burst", 27)),
                    seen=("The elite swings Attack every time, never AttackLeft (research's pick, AR2 section 10): in AttackLeft its second mask",
        "cuts into the first from 26 to 31, so that swing is the ordinary Shade's only. Nothing here crosses anything.")),
    # AR57: each plays its own move's elite clip; the ordinary one is measured beside it
    "Guard": dict(type="Green", clips=("GuardElite", "Guard", "Attack", "HitLeft", "Burst", "Idle", "Walk", "Hit"),
                  named={"GuardElite": (44, "braced"), "Guard": (44, "braced"), "Attack": (30, "Hit"), "HitLeft": (3, "struck")},
                  side=(("Guard", "GuardElite", 24), ("Guard", "GuardElite", 44), ("Burst", "Burst", 27)),
                  seen=()),
    "Dasher": dict(type="Orange", clips=("LungeElite", "Lunge", "Attack", "HitLeft", "Burst", "Idle", "Walk", "Hit"),
                   named={"LungeElite": (40, "the tell"), "Lunge": (40, "the tell"), "Attack": (30, "Hit"), "HitLeft": (3, "struck")},
                   side=(("Lunge", "LungeElite", 40), ("Lunge", "LungeElite", 98), ("Burst", "Burst", 27)),
                   # the landing, where both sleeves are flung forward (the check's second condition)
                   also=(("LungeElite", 81, "the mask arrives"), ("LungeElite", 88, "the rest arrives")),
                   seen=()),
}


def found_in(folders, file):
    for folder in folders:
        if (folder / file).exists():
            return folder / file
    raise SystemExit(f"No {file} in {', '.join(map(str, folders))}")




def key_clips(rig, clips, folders):
    """Every clip on its own stretch of the timeline: {clip: (start, last frame)}."""
    spans = {}
    for i, clip in enumerate(clips):
        data = json.loads(found_in(folders, f"Shade_{clip}.json").read_text())
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


def glow(objects, colour):
    """The game's glow: the body in `colour` at its strength, every mask in its own tint at a mask's."""
    for material in {slot.material for o in objects for slot in o.material_slots}:
        nodes = material.node_tree.nodes
        tint = next(n for n in nodes if n.bl_idname == "ShaderNodeMix" and n.blend_type == "MULTIPLY")
        strength = next(n for n in nodes if n.bl_idname == "ShaderNodeMath" and n.operation == "MULTIPLY")
        mask = "Mask" in material.name
        tint.inputs[7].default_value = rs.srgb(sm.MASK_TINT if mask else colour)
        strength.inputs[1].default_value = MASK if mask else BODY
        print(f"{material.name}: {sm.MASK_TINT if mask else colour} at {MASK if mask else BODY}")


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
        low = (math.inf, start)  # the second mask's lowest point over the floor
        crossed = {name: [] for name in near}
        for f in range(start, start + last + 1):
            scene.frame_set(f)
            xs = np.concatenate([(local[o.name] @ np.array(o.matrix_world).T)[:, :3] @ right for o in shown])
            widest = max(widest, (float(xs.max() - xs.min()), f))
            mask = tree(copy)
            world = [copy.matrix_world @ v.co for v in copy.data.vertices]
            low = min(low, (min(p.z for p in world), f))
            for name, o in near.items():
                piece = tree(o)
                if mask.overlap(piece):
                    crossed[name].append(f - start)
                gap = min(piece.find_nearest(p)[3] for p in world)
                if gap < gaps[name][0]:
                    gaps[name] = (gap, f)
        found[clip] = {"widest": (widest[1] - start, round(widest[0], 2)),
                       "near": {name: (round(g, 3), f - start) for name, (g, f) in gaps.items()},
                       "crossed": crossed, "floor": (round(low[0], 3), low[1] - start)}
        print(f"{clip}: widest at {widest[1] - start} ({widest[0]:.2f} studs across the camera); nearest "
              + ", ".join(f"{name} {g:.3f} at {f - start}" for name, (g, f) in gaps.items())
              + "; crossing " + (", ".join(f"{n} at {c}" for n, c in crossed.items() if c) or "none")
              + f"; lowest {low[0]:.2f} over the floor at {low[1] - start}")
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
    args = sys.argv[sys.argv.index("--") + 2:]
    kind = args[0] if args else "Brawler"
    folders = [Path(a) for a in args[1:]] + [HANDOFF / "clips", HANDOFF]
    clips, named, side, seen = (SETS[kind][k] for k in ("clips", "named", "side", "seen"))
    tint = TINT
    if kind != "Brawler":
        import hard_cut as hc
        tint = "#" + hc.type_tints()[SETS[kind]["type"]]
    stem = "shade_elite_contact" if kind == "Brawler" else f"shade_elite_contact_{kind}"
    wear(kind)
    bpy.context.view_layer.update()
    first = bpy.data.objects[recipe["masks"][kind]["name"]]
    bare = json.loads(found_in(folders, f"Shade_Mask{kind}Bare.json").read_text())
    copy = eb.mesh_object(f"Elite{kind}Bare", bare, first.material_slots[0].material)
    eb.wear(rig, copy, recipe["elite"]["masks"]["Brawler"] if kind == "Brawler" else se.placement(kind, bare["c"]))
    bpy.data.objects["Floor"].hide_render = True
    body = [bpy.data.objects[p["name"]] for p in recipe["pieces"]]
    glow(body + [first], tint)
    spans = key_clips(rig, clips, folders)
    by_part = {p["name"]: p["on"] for p in recipe["pieces"]}
    near = {"Torso": next(o for o in body if by_part[o.name] == "Torso"),
            "RightArm": next(o for o in body if by_part[o.name] == "Right Arm"), "Mask": first,
            "LeftLeg": next(o for o in body if by_part[o.name] == "Left Leg"),
            "RightLeg": next(o for o in body if by_part[o.name] == "Right Leg")}
    assert tuple(near) == NEAR
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
    for clip in clips:
        row.append((clip, found[clip]["widest"][0], "widest"))
        if clip in named and named[clip][0] != found[clip]["widest"][0]:
            row.append((clip, *named[clip]))
    # band B: the four first's named frame, then where the second mask comes nearest anything, or first crosses it
    close = []
    for clip in clips[:4]:
        close.append((clip, *named[clip]))
        crossings = sorted(f for c in found[clip]["crossed"].values() for f in c)
        gap, at = min(found[clip]["near"].values())
        what, at = ("crosses", crossings[0]) if crossings else (f"nearest, {gap:.2f}", at)
        if at != named[clip][0]:
            close.append((clip, at, what))

    also = list(SETS[kind].get("also", ()))
    row += also
    close += also
    W, H = max(2400, 40 + 120 * len(row) + 40 + 6 * 112 + 40), 1640
    ink, soft, pale = "#1E1B22", "#6A655E", "#B9B4C6"
    page = rs.canvas(W, H, rs.PAPER)
    text = [(40, 26, 40, "THE ELITE, CONTACT SHEET", ink),
            (40, 80, 17, f"AR2, section 5, condition 9. The {kind} elite ({se.SCALE:g}) with its second mask, the copy without ties where the game "
                         f"puts it, from the player's camera. Body {tint} at {BODY:g}, masks {sm.MASK_TINT} at {MASK:g}, lit in Eevee: no engine "
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
        first4 = clip in named
        text.append((x0 + c * col + 6, y0 + 268, 13, clip, ink if first4 else soft))
        text.append((x0 + c * col + 6, y0 + 286, 13, f"{frame}, {label}", ink if first4 else soft))
    # band A, right: the ordinary Shade and the elite side by side
    x1, pc = x0 + col * len(row) + 40, 112
    text.append((x1, y0 - 34, 16, "Beside the ordinary Shade (16/6 check, condition 2)", soft))
    for c, (clip, big, frame) in enumerate(side):
        frame = found[clip]["widest"][0] if frame is None else frame
        for r, dusk in enumerate((True, False)):
            y = y0 + r * 132
            rs.fill(page, x1 + c * 2 * pc, y, 2 * pc, 128, rs.NIGHT if dusk else rs.DAY)
            rs.stand(page, rs.shrink(picture(clip, frame, dusk, worn=False), F64), x1 + c * 2 * pc, y + 120, pc)
            rs.stand(page, rs.shrink(picture(big, frame, dusk), F64 * se.SCALE), x1 + c * 2 * pc + pc - 14, y + 120, pc)
        text.append((x1 + c * 2 * pc + 6, y0 + 268, 13, f"{clip} {frame}", ink))
    text.append((x1, y0 + 296, 13, "Each pair: the ordinary Shade, then the elite.", soft))
    text.append((x1, y0 + 314, 13, "The Shade has no fallen pose: Burst 27 is its last,", soft))
    text.append((x1, y0 + 332, 13, "standing, and the game hides it there.", soft))

    # band B: the four first, larger, at dusk
    y1, bc = 560, 236
    text.append((x0, y1 - 30, 16, ", ".join(clips[:4]) + ", larger, at dusk: the frame condition 9 names, then where the second mask comes nearest the coat, the other sleeve, the first mask or a leg", soft))
    rs.fill(page, x0, y1, bc * len(close), 330, rs.NIGHT)
    for c, (clip, frame, label) in enumerate(close):
        rs.stand(page, rs.shrink(picture(clip, frame, True), BIG * se.SCALE), x0 + c * bc, y1 + 318, bc)
        text.append((x0 + c * bc + 10, y1 + 336, 14, f"{clip} {frame}, {label}", ink))
    # band C: each at its widest, larger, at dusk
    y2 = 960
    text.append((x0, y2 - 30, 16, "Each clip the elite plays at its widest, larger, at dusk", soft))
    rs.fill(page, x0, y2, bc * len(clips), 330, rs.NIGHT)
    for c, clip in enumerate(clips):
        frame = found[clip]["widest"][0]
        rs.stand(page, rs.shrink(picture(clip, frame, True), BIG * se.SCALE), x0 + c * bc, y2 + 318, bc)
        text.append((x0 + c * bc + 10, y2 + 336, 14, f"{clip} {frame}", ink))
    # the measures
    y3 = 1340
    text.append((x0, y3, 16, "Every frame of every clip, at an ordinary Shade's size: the second mask's nearest approach to the coat, the other sleeve, the first mask and the legs "
                             "(studs, at its frame), and any frame where its triangles cross theirs", ink))
    for i, clip in enumerate(clips):
        near_, crossed = found[clip]["near"], found[clip]["crossed"]
        legs = min(near_["LeftLeg"], near_["RightLeg"])
        crossing = "; crosses " + ", ".join(f"{n} at {c[0]} to {c[-1]}" for n, c in crossed.items() if c) if any(crossed.values()) else "; crosses nothing"
        line = (f"{clip}: coat {near_['Torso'][0]:.2f} at {near_['Torso'][1]}, sleeve {near_['RightArm'][0]:.2f} at {near_['RightArm'][1]}, "
                f"first mask {near_['Mask'][0]:.2f} at {near_['Mask'][1]}, legs {legs[0]:.2f} at {legs[1]}{crossing}")
        text.append((x0 + (i // 5) * 1180, y3 + 34 + (i % 5) * 24, 14, line, ink if clip in named else soft))
    for i, line in enumerate(seen):
        text.append((x0 + 1180, y3 + 34 + (4 + i) * 24, 14, line, ink))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / f"{stem}.png")
    # its parts as their own files, each under 2,000 pixels wide, so a reader sees the 64 px tiles at their own size
    parts = [("64", (0, y0 - 44, x0 + col * len(row) + 20, 350)), ("beside", (x1 - 20, y0 - 44, 6 * pc + 40, 400)),
             ("widest", (0, y2 - 40, x0 + bc * len(clips) + 20, 400))]
    for i in range(0, len(close), 8):  # the larger band, eight tiles a file
        n = min(8, len(close) - i)
        parts.append((f"large{i // 8 + 1}", (x0 + bc * i - 20 if i else 0, y1 - 40, bc * n + (40 if i else x0 + 20), 400)))
    for part, (x, y, w, h) in parts:
        rs.save(page[y:y + h, x:x + w].copy(), out / f"{stem}_{part}.png")
    (out / f"{stem}.json").write_text(json.dumps(found, indent=1))
    print(f"wrote {out / (stem + '.png')}")

if __name__ == "__main__":
    main()
