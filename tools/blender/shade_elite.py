"""The elite Shade's second mask (AR2): where it sits, drawn beside an ordinary Shade, and its placement for the recipe.

blender.exe -b --factory-startup --python tools/blender/shade_elite.py -- <out_dir> [write]

An elite is a larger Shade with a second mask on its shoulder (docs/roster.md). The second mask is the Shade's own
mask again, smaller, tied to its left arm just under the shoulder: no new mesh and no new map, so the builder clones
the mask's MeshPart, sizes it and welds it to the Left Arm. The left arm, because the player's camera sits behind the
lead's right shoulder, and a Shade that faces the lead shows that camera its front and its left side.

The sheet compares the ways it can sit (WAYS), each on the Brawler at the elite's size beside an ordinary Shade, then
the picked way (PICK) on all four masks. Workbench only, so no GPU turn; the blockout's shapes are shade_sheet.py's,
and so is the frame: studs, X right, Y forward, Z up. `write` puts the picked placement into the delivered recipe,
build/handoff/Shade/Shade.recipe.json, under "elite", in the recipe's own frame.
"""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Euler, Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_sheet as ss  # noqa: E402

RECIPE = Path(__file__).resolve().parents[2] / "build" / "handoff" / "Shade" / "Shade.recipe.json"
SCALE = 1.35     # the elite's size against an ordinary Shade's: the game's number (Definitions/Enemies), drawn here
SMALL = 0.6      # the second mask's size against the one on the face
FACE = Vector((0.0, ss.MASK_Y + 0.07, 4.85))  # the middle of a mask's paper where it's built, on the face
# each way: where that middle goes, on the left arm, and how the mask is turned (degrees about X, Y, Z, in that order;
# a mask is built facing forward, +Y, so 90 about Z faces it out to the Shade's left)
WAYS = {"A": ("on the arm, facing out", (-2.13, 0.0, 3.5), (0, 0, 90)),
        "B": ("on the arm's front corner", (-2.07, 0.615, 3.55), (0, 8, 45)),  # clear of the sleeve's corner by 0.05
        "C": ("pushed up onto the shoulder", (-1.72, 0.12, 4.08), (-48, 0, 62))}
PICK = "B"
PLAYER = (204, 18)   # the player's camera on a Shade that faces the lead: its front and its left
OTHER = (156, 18)    # the same from the lead's other side
QUARTER = (225, 6)
BEHIND = (25, 18)
DUSK = rs.rgb("#2F2148")


def turn(degrees):
    return Euler([math.radians(d) for d in degrees], "XYZ").to_matrix().to_4x4()


def second(joints, kind, m, way):
    """Ties a second mask of `kind` to the left arm, the given way."""
    _, at, degrees = WAYS[way]
    holder = bpy.data.objects.new("SecondMask", None)
    bpy.context.scene.collection.objects.link(holder)
    holder.parent = joints["ls"]
    holder.matrix_parent_inverse = Matrix.Translation(-Vector(ss.PIVOTS["ls"]))
    holder.matrix_basis = Matrix.Translation(at) @ turn(degrees) @ Matrix.Scale(SMALL, 4)
    for o in ss.mask(kind, m):
        o.parent = holder
        o.matrix_parent_inverse = Matrix.Translation(-FACE)


def take(kind, way, views, size=(1000, 1000), span=10.0, centre=(0, 0, 3.0)):
    """One Shade as it stands, with a second mask if `way` names one: {view: picture}."""
    scene = bl.reset_scene()
    colour = ss.MASKS[kind][0]
    m = ss.materials(colour)
    joints = ss.build(scene, kind, m)
    if way:
        second(joints, kind, m, way)
    ss.POSES["hung"](joints)
    out = {}
    for view, (azimuth, elevation) in views.items():
        passes = []
        for flat in (False, True):
            rs.workbench(scene, *size, flat=flat)
            path = OUT / f"_{view}_{int(flat)}.png"
            passes.append(rs.shoot(scene, path, azimuth, elevation, centre, span))
            path.unlink()
        out[view] = ss.lit(*passes, rs.rgb(ss.TYPES[colour]), reach=round(size[0] * 0.012))
    return out


def placement(kind, recipe):
    """The picked way in the recipe's frame (Roblox: Y up, facing -Z), at the ordinary Shade's size: where the
    mask's own middle goes, and which way its three axes point."""
    _, at, degrees = WAYS[PICK]
    centre = recipe["masks"][kind]["centre"]                    # the mask's MeshPart, on the face
    own = Vector((centre[0], -centre[2], centre[1]))            # the same point in this script's frame
    basis = Matrix.Translation(at) @ turn(degrees) @ Matrix.Scale(SMALL, 4) @ Matrix.Translation(-FACE)
    to_roblox = lambda v: [round(v.x, 4), round(v.z, 4), round(-v.y, 4)]  # noqa: E731
    r = turn(degrees).to_3x3()
    return {"centre": to_roblox(basis @ own),
            "right": to_roblox(r @ Vector((1, 0, 0))), "up": to_roblox(r @ Vector((0, 0, 1))),
            "facing": to_roblox(r @ Vector((0, 1, 0)))}


def sheet():
    views = {"player": PLAYER, "quarter": QUARTER, "other": OTHER, "behind": BEHIND}
    plain = take("Brawler", None, views)
    ways = {way: take("Brawler", way, views) for way in WAYS}
    kinds = {kind: take(kind, PICK, {"player": PLAYER, "quarter": QUARTER}) for kind in ss.MASKS if kind != "Brawler"}

    W, H = 1920, 1200
    page = rs.canvas(W, H, rs.PAPER)
    ink, soft = "#1E1B22", "#6A655E"
    text = [(40, 30, 48, "THE ELITE'S SECOND MASK", ink),
            (40, 92, 20, f"The Shade's own mask again at {SMALL:g} of its size, tied to the left arm under the shoulder. "
                         f"The elite is {SCALE:g} times an ordinary Shade. Three ways it can sit; {PICK} is picked.", soft)]

    # row A: an ordinary Shade, then each way at the elite's size, from the player's camera and from the front left
    k, floor = 0.42, 640
    rs.stand(page, rs.shrink(plain["player"], k), 20, floor, 250)
    text.append((34, floor + 14, 18, "an ordinary Shade", soft))
    for i, (way, (label, _, _)) in enumerate(WAYS.items()):
        x = 280 + i * 545
        rs.stand(page, rs.shrink(ways[way]["player"], k * SCALE), x, floor, 290)
        rs.stand(page, rs.shrink(ways[way]["quarter"], k * SCALE), x + 260, floor, 290)
        text.append((x + 14, floor + 14, 18, f"{way}: {label}", ink if way == PICK else soft))
        text.append((x + 14, floor + 38, 15, "the player's camera, and the front left", soft))
    rs.fill(page, 30, floor + 2, W - 60, 2, rs.rgb("#BDB8AE"))

    # row B: at 64 px for a 5 stud body, over dark, dusk and bright: ordinary, then each way from the player's camera,
    # from the lead's other side and from behind
    f64 = 64 / 500
    x0, y0 = 40, 720
    text.append((x0, y0, 18, "at 64 px: an ordinary Shade, then A, B, C from the player's camera, from the lead's other side, from behind", soft))
    shots = [plain["player"]] + [ways[w][v] for v in ("player", "other", "behind") for w in WAYS]
    for r, ground in enumerate((rs.NIGHT, DUSK, rs.DAY)):
        y = y0 + 30 + r * 134
        rs.fill(page, x0, y, 1130, 130, ground)
        for c, shot in enumerate(shots):
            rs.stand(page, rs.shrink(shot, f64 * (SCALE if c else 1)), x0 + 6 + c * 112, y + 126, 108)

    # the picked way on the other three masks
    x0 = 1220
    text.append((x0, y0, 18, f"{PICK} on the other three masks, at the elite's size", soft))
    for c, (kind, shot) in enumerate(kinds.items()):
        rs.stand(page, rs.shrink(shot["player"], 0.25 * SCALE), x0 - 20 + c * 225, 1140, 240)
        text.append((x0 + 40 + c * 225, 1150, 16, kind, soft))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, OUT / "shade_elite.png")


def write():
    recipe = json.loads(RECIPE.read_text(encoding="utf-8"))
    recipe["elite"] = {
        "note": "An elite wears its own mask twice: the second is the same MeshPart again, with the same surface, "
                "mask_tint and mask_strength, at `size` of the first, welded to the Left Arm. `centre` is where that "
                "MeshPart's middle goes and `right`, `up` and `facing` where its own +X, +Y and -Z point, in this "
                "recipe's frame at the ordinary Shade's size: all of it scales with the rig. The clone's ties and "
                "knot end up inside the sleeve; nothing runs from it to the collar or the first mask. Only the "
                "Brawler's is past the content check (docs/asset-requests.md, AR2, section 5).",
        "on": "Left Arm", "size": SMALL, "way": WAYS[PICK][0],
        "masks": {kind: placement(kind, recipe) for kind in ss.MASKS}}
    RECIPE.write_text(json.dumps(recipe, indent=1))  # as shade_model.py writes it
    print("recipe: elite written,", json.dumps(recipe["elite"]["masks"]["Brawler"]))


if __name__ == "__main__":
    OUT = rs.OUT = ss.OUT = bl.out_dir()
    sheet()
    if "write" in sys.argv[sys.argv.index("--") + 2:]:
        write()
