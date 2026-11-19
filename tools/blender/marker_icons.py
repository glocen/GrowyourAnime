"""TR10: the down marker's two icons, the elite's and the Lamplighter's (docs/test-requests.md, TR10). While one is down,
its icon hangs over the empty square or the keeper's gate with the time left, so the player knows who comes back.

Read at 40 points over the street, each shows its face and its sign, from the character's own delivery (its meshes and
maps in build/handoff, the surfaces as Roblox draws them):
  Elite        the Brawler's mask over its shoulder, and the second, smaller mask on its arm, both turned to you: the
               two masks are what make it the elite and not a pack's Brawler. AR47's mask (2026-11-19): no ink, its
               almond holes and grin lit white on tan paper, as the game draws it
  Lamplighter  his masked head under the hat, and his lantern lit beside it, brought in from the pole's end for the
               picture (the pole itself stays out: at 40 points it is a line across the face)

Images at 160 pixels square on transparency (40 points at the kit's 4 a point), laid on the marker's icon tile in place of
the name's letter. The sheet shows each close, on the tile at 40 points and at 2 a point, and alone at 40 and 28 px.

Run: blender -b --factory-startup --python tools/blender/marker_icons.py -- <out>
"""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import hud_art as ha  # noqa: E402
import lamplighter_model as lm  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_model as sm  # noqa: E402

HANDOFF = Path(__file__).resolve().parents[2] / "build" / "handoff"
SIZE = 160            # pixels: 40 points at 4 a point
RENDER = 640          # rendered at four times, then shrunk
RED = "#EA4B4F"       # the elite's type on Lantern Row (Definitions.Enemies: brawler_elite, Red), the recipe's Strength
PLATE_HIGH, LINE, PLATE = (46, 50, 59), (92, 98, 112), (32, 35, 42)   # Theme.Colour: the tile, its stroke, the panel

# Each icon's camera: azimuth (180 face on; more comes round to the character's left), elevation, the crop's middle
# (Blender's frame: facing +Y, feet on z = 0) and its height in studs.
VIEW = dict(Elite=dict(azimuth=204.0, elevation=4.0, centre=(-0.55, 0.0, 4.3), span=4.6),
            Lamplighter=dict(azimuth=160.0, elevation=6.0, centre=(-0.3, 0.0, 5.0), span=5.6))
# The body's glow in the icon, a share of the game's: the type's colour as a hint at the edges, not a lit seam down
# the middle of a 40-point picture (the elite's red there read as a stripe under its mask).
BODY_GLOW = 0.25
# The elite's masks as the game draws them: tan paper with its holes and grin lit white (AR47's capture: the paper
# about (205, 179, 152), the cuts (255, 255, 229)). The icon's sun, fill and the paper's own glow at the model's 12
# clipped the paper to white, so with AR47's brows gone the lit cuts vanished into it. Here the paper's diffuse is
# scaled and warmed and the glow brought down, which draws the paper at about (209, 191, 165).
PAPER_LIGHT = (0.5, 0.45, 0.39)
MASK_GLOW = 3.5


def piece(folder, record_name, name, material):
    return ha.delivered_piece(name, json.loads((folder / record_name).read_text(encoding="utf-8")), material)


def paper_lit(material):
    """The mask's diffuse scaled by PAPER_LIGHT (its glow, which the cuts carry, untouched)."""
    nodes, links = material.node_tree.nodes, material.node_tree.links
    bsdf = nodes["Principled BSDF"]
    source = bsdf.inputs["Base Color"].links[0].from_socket
    dim = nodes.new("ShaderNodeMix")
    dim.data_type, dim.blend_type = "RGBA", "MULTIPLY"
    dim.inputs[0].default_value = 1.0
    links.new(source, dim.inputs[6])
    dim.inputs[7].default_value = (*PAPER_LIGHT, 1.0)
    links.new(dim.outputs[2], bsdf.inputs["Base Color"])


def elite():
    """The Shade's upper body, its Brawler mask, and the elite's second mask on the arm's front corner (the recipe's
    `elite`: the bare copy, 0.6 of the first, placed by its own axes)."""
    folder = HANDOFF / "Shade"
    recipe = json.loads((folder / "Shade.recipe.json").read_text(encoding="utf-8"))
    paths = {kind: folder / file for kind, file in recipe["maps"].items()}
    body, lit = sm.baked("ShadeBody", paths)
    lit(RED, sm.HOT * BODY_GLOW)
    mask, lit = sm.baked("ShadeMask", paths)
    lit(sm.MASK_TINT, MASK_GLOW)
    paper_lit(mask)
    objects = [piece(folder, f"{n}.json", n, body) for n in ("Shade_Torso", "Shade_RightArm", "Shade_LeftArm")]
    objects.append(piece(folder, recipe["masks"]["Brawler"]["mesh"], "Mask", mask))
    second = recipe["elite"]["masks"]["Brawler"]
    record = json.loads((folder / second["mesh"]).read_text(encoding="utf-8"))
    record = dict(record, c=[0.0, 0.0, 0.0])   # about its own middle, then placed
    obj = ha.delivered_piece("SecondMask", record, mask)
    turned = lambda v: Vector((v[0], -v[2], v[1]))  # noqa: E731  Roblox's frame to Blender's
    right, up, facing = turned(second["right"]), turned(second["up"]), turned(second["facing"])
    # a mesh point (x, y, z) in its own Roblox frame, here as Blender's (x, -z, y): its +X goes to `right`, +Y to `up`
    # and -Z to `facing`, so Blender's +Y (its -Z) goes to `facing` and Blender's +Z (its +Y) to `up`
    axes = Matrix((right, facing, up)).transposed().to_4x4()
    size = recipe["elite"]["size"]
    obj.data.transform(Matrix.Translation(turned(second["centre"])) @ axes @ Matrix.Scale(size, 4))
    objects.append(obj)
    return objects


def lamplighter():
    """His upper body and head (the mask, the hat and its cords), and his lantern, lit, brought in beside his head."""
    folder = HANDOFF / "Lamplighter"
    recipe = json.loads((folder / "Lamplighter.recipe.json").read_text(encoding="utf-8"))
    paths = {kind: folder / file for kind, file in recipe["maps"].items()}
    glow = recipe["emissive"]
    mats = dict(body=lm.look("LampBody", paths, glow["body"]["tint"], glow["body"]["strength"] * BODY_GLOW),
                head=lm.look("LampHead", paths, glow["head"]["tint"], glow["head"]["strength"]),
                lantern=lm.look("LampLantern", paths, glow["lantern"]["tint"], glow["lantern"]["hot"]))
    objects = [piece(folder, f"{n}.json", n, mats["body"]) for n in ("Lamplighter_Torso", "Lamplighter_LeftArm",
                                                                    "Lamplighter_RightArm")]
    objects.append(piece(folder, "Lamplighter_Head.json", "Head", mats["head"]))
    lantern = piece(folder, "Lamplighter_Lantern.json", "Lantern", mats["lantern"])
    pts = [v.co for v in lantern.data.vertices]
    middle = sum(pts, Vector()) / len(pts)
    # beside the head on his left, which this view puts on the picture's right, low and forward, at 0.75 of its size
    lantern.data.transform(Matrix.Translation(Vector((-2.05, 0.4, 3.85))) @ Matrix.Scale(0.75, 4) @ Matrix.Translation(-middle))
    objects.append(lantern)
    return objects


BUILD = dict(Elite=elite, Lamplighter=lamplighter)


def shoot(name, out: Path):
    scene = bl.reset_scene()
    scene.world = bpy.data.worlds.new("Icon")
    for obj in BUILD[name]():
        scene.collection.objects.link(obj)
    bpy.context.view_layer.update()
    v = VIEW[name]
    rm.eevee(scene, RENDER, RENDER)
    rm.sun_for(scene, v["azimuth"])
    a = math.radians(v["azimuth"])   # a fill from the camera, as the portraits have: the masks' cuts mustn't sit in shade
    fill = bpy.data.objects.new("Fill", bpy.data.lights.new("Fill", "SUN"))
    fill.data.energy, fill.data.use_shadow = 1.1, False
    scene.collection.objects.link(fill)
    fill.rotation_euler = Vector((-math.sin(a), math.cos(a), -0.12)).to_track_quat("-Z", "Y").to_euler()
    path = out / f"_{name}.png"
    shot = rs.shoot(scene, path, v["azimuth"], v["elevation"], v["centre"], v["span"])
    path.unlink()
    return shot


def tile(size, picture, ground=PLATE_HIGH):
    """The marker's icon tile: Theme's PlateHigh, a quarter-round corner, its Line stroke, the picture over it."""
    import numpy as np
    s = size
    page = rs.canvas(s, s, tuple(c / 255 for c in PLATE))
    yy, xx = np.mgrid[0:s, 0:s] + 0.5
    r = 0.25 * s
    dx = np.maximum(np.maximum(r - xx, xx - (s - r)), 0)
    dy = np.maximum(np.maximum(r - yy, yy - (s - r)), 0)
    edge = r - np.hypot(dx, dy)                         # distance inside the rounded square
    inside = np.clip(edge + 0.5, 0, 1)[..., None]
    stroke = np.clip(edge + 0.5, 0, 1) - np.clip(edge - max(1.5 * s / 40, 1.0) + 0.5, 0, 1)
    fill = np.array([c / 255 for c in ground])
    line = np.array([c / 255 for c in LINE])
    page[..., :3] = page[..., :3] * (1 - inside) + fill * inside
    rs.paste(page, rs.shrink(picture, s / picture.shape[1]), 0, 0)
    page[..., :3] = page[..., :3] * (1 - stroke[..., None]) + line * stroke[..., None]
    return page


def sheet(out: Path, shots):
    W, H = 1100, 680
    page = rs.canvas(W, H, tuple(c / 255 for c in PLATE))
    ink, soft = "#F2ECE2", "#B9B2C4"
    text = [(24, 18, 24, "Grow your Anime: the down marker's icons, the elite's and the Lamplighter's (TR10)", ink),
            (24, 52, 13, "Each its face and its sign, from its own delivery: the elite's two masks; the Lamplighter's hat and "
                         "lantern. On the marker's tile (Theme's PlateHigh, its Line stroke), in place of the letter.", soft)]
    for i, name in enumerate(shots):
        x, y = 24 + i * 540, 92
        back = rs.canvas(320, 320, tuple(c / 255 for c in PLATE_HIGH))
        rs.paste(back, rs.shrink(shots[name], 320 / shots[name].shape[1]), 0, 0)
        rs.paste(page, back, x, y)
        rs.paste(page, tile(80, shots[name]), x + 340, y)          # 40 points at 2 a point
        rs.paste(page, tile(40, shots[name]), x + 340, y + 100)    # 40 points at 1 a point
        rs.paste(page, tile(28, shots[name]), x + 400, y + 106)    # a small phone's
        text.append((x, y + 330, 16, name, ink))
        text.append((x + 340, y + 160, 11, "on the tile: 80 px (2 a point),", soft))
        text.append((x + 340, y + 176, 11, "40 px and 28 px", soft))
        # the upload file as it is, at full size and at 64 px, over dark (the content check's look)
        upload = rs.shrink(shots[name], SIZE / shots[name].shape[1])
        for k, (size, ground) in enumerate(((SIZE, (0.05, 0.045, 0.07)), (64, (0.05, 0.045, 0.07)), (64, (0.78, 0.78, 0.8)))):
            back = rs.canvas(size, size, ground)
            rs.paste(back, rs.shrink(upload, size / SIZE), 0, 0)
            rs.paste(page, back, x + [0, 180, 260][k], y + 370)
        text.append((x, y + 540, 11, f"Marker{name}.png as uploaded: {SIZE} px, and at 64 px over dark and bright", soft))
    rs.OUT = out
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "marker_icons.png")


def main():
    out = bl.out_dir()
    images = out / "images"
    images.mkdir(parents=True, exist_ok=True)
    shots = {}
    for name in BUILD:
        shots[name] = shoot(name, out)
        rs.save(rs.shrink(shots[name], SIZE / shots[name].shape[1]), images / f"Marker{name}.png")
    sheet(out, shots)
    print("wrote", out / "marker_icons.png")


if __name__ == "__main__":
    main()
