"""AR3 section 3, the HUD's own art (docs/asset-requests.md; docs/ui.md, "The HUD, in the world"): each launch
Voidkin's portrait for the lead's card, cut to its rarity frame's mask; one silhouette for a Voidkin that isn't made
yet; and the brush stroke under a critical number.

A portrait is the Voidkin's own model, head and shoulders, the body three-quarter on and the head turned back to the
player, so the eyes meet whoever holds the phone. The engine can't clip a picture to a cut corner, so each is cut here
to its frame's mask (the UI kit's, `build/handoff/UI/kit/masks/`), on the frame's own canvas: the builder lays it
where the frame goes, between the frame's Back and the frame.

Run, each a headless Blender job:
  ... --python tools/blender/hud_art.py -- <out> contact     the heads alone, to choose the angles
  ... --python tools/blender/hud_art.py -- <out> make        every image, into <out>/images
  ... --python tools/blender/hud_art.py -- <out> sheet       the review sheet, from the images
Naming Voidkin after `contact` or `make` shoots those alone: `make` then keeps every other image and its listing as
they are. `review <names>` is the sheet for those alone, beside Rook's, for a portrait added after the launch three.
"""
import json
import math
import re
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
MODELS = REPO / "build" / "scratch" / "modulo"
HANDOFF = REPO / "build" / "handoff"
# Whose model is read from its delivery (build/handoff/<Name>: the recipe, its meshes and its maps), not from a .blend.
# Watt's only .blend is the first design's, which left the game (AR11, delivery 3).
DELIVERED = ("Watt", "Kirra")
KIT = REPO / "build" / "handoff" / "UI" / "kit"
K = 4            # pixels a point in a slice, the kit's
NECK = Vector((0.0, 0.0, 4.0))  # R6's neck: the head turns about it
RENDER = (624, 752)  # a portrait's render: twice the full cut's opening, 78 by 94 points

# Who each is, in the one look the card holds. `side`: which shoulder is to the camera (+1 the Voidkin's right).
# `body`: degrees the body is turned off the camera. `turn`: how far of that the head comes back to the player.
# `tilt` (ear to shoulder) and `nod` (+ chin down), degrees. `centre` and `span`: the crop's middle and its height, in
# studs. `head`: the parts that turn with the head. `hide`: what the crop is better without.
PORTRAITS = {
    # A street brawler sizing you up: the gauntlet's shoulder forward, chin down, a level look from under the brow.
    "Rook": dict(side=1, body=34, turn=22, tilt=-3, nod=5, elevation=3, centre=(-0.1, 0, 4.62), span=2.45,
                 head=("Rook_Head",), hide=()),
    # An apprentice under a hat too big: head cocked up at you from under the brim, eager, a little unsure.
    "Pip": dict(side=-1, body=30, turn=20, tilt=8, nod=-4, elevation=-2, centre=(0.0, 0, 4.86), span=2.75,
                head=("Pip_Head", "Pip_Hat"), hide=()),
    # A singer between songs: composed, chin a touch up, the headset to the camera. Her staff stands out of the crop:
    # at the card's size it's a line through her face.
    "Lyric": dict(side=1, body=32, turn=22, tilt=4, nod=-2, elevation=2, centre=(0.0, 0, 4.56), span=2.55,
                  head=("Lyric_Head", "Lyric_HeadEdge"), hide=("Lyric_Staff",)),
    # The quiet wall: the collar up to his nose, so the eyes do the talking, level and steady over it. The pale band
    # across his chest is the sling, the coat's own; the spear itself hardly enters the crop.
    "Watt": dict(side=1, body=30, turn=20, tilt=0, nod=3, elevation=2, centre=(0.0, 0, 4.45), span=2.85,
                 head=("Watt_Head",), hide=()),
    # The courier: a quick sideways look back over the shoulder, a touch sly, her scarf's tail over the near shoulder.
    "Kirra": dict(side=-1, body=38, turn=26, tilt=-5, nod=2, elevation=1, centre=(0.0, 0, 4.35), span=2.7,
                  head=("Kirra_Head",), hide=()),
}


def voidkin_rarity(name):
    """A Voidkin's rarity, read from the game's own table."""
    text = (REPO / "src" / "shared" / "Definitions" / "Voidkin.luau").read_text(encoding="utf-8")
    found = re.search(r'Name = "%s", Rarity = "(\w+)"' % name, text)
    if not found:
        raise SystemExit(f"{name} isn't in Definitions.Voidkin")
    return found.group(1)


def delivered_piece(name, record, material):
    """A delivered mesh where it stands at rest (its points are about its centre `c`), turned to Blender's frame, with
    its UVs and its own normals."""
    def turned(v):
        return (v[0], -v[2], v[1])

    p, n, t, c = record["p"], record["n"], record["t"], record["c"]
    tris = [record["f"][i:i + 9] for i in range(0, len(record["f"]), 9)]   # corners, their normals, their UVs
    data = bpy.data.meshes.new(name)
    data.from_pydata([turned((p[i] + c[0], p[i + 1] + c[1], p[i + 2] + c[2])) for i in range(0, len(p), 3)], [],
                     [tuple(tri[:3]) for tri in tris])
    uv = data.uv_layers.new(name="UVMap")
    normals = []
    for poly, tri in zip(data.polygons, tris):
        poly.use_smooth = True
        for loop, k in zip(poly.loop_indices, tri[6:9]):
            uv.data[loop].uv = (t[2 * k], 1 - t[2 * k + 1])
        normals += [turned(n[3 * k:3 * k + 3]) for k in tri[3:6]]
    data.normals_split_custom_set(normals)
    data.materials.append(material)
    return bpy.data.objects.new(name, data)


def delivered(name):
    """A Voidkin as delivered: its recipe's pieces at rest on its maps, its glow cold, as it stands (the recipe's
    `cold`). The Roblox frame turned to the .blend's: facing +Y, the feet on z = 0."""
    folder = HANDOFF / name
    recipe = json.loads((folder / f"{name}.recipe.json").read_text(encoding="utf-8"))
    material = rm.baked(name, {kind: folder / file for kind, file in recipe["maps"].items()}, 0.0)
    return [delivered_piece(piece["name"], json.loads((folder / piece["mesh"]).read_text(encoding="utf-8")), material)
            for piece in recipe["pieces"]]


def shoot_portrait(name, out: Path, size=RENDER):
    """One Voidkin's head and shoulders, on transparency."""
    p = PORTRAITS[name]
    scene = bl.reset_scene()
    scene.world = bpy.data.worlds.new("Portrait")
    if name in DELIVERED:
        objects = delivered(name)
    else:
        with bpy.data.libraries.load(str(MODELS / name.lower() / "model" / f"{name.lower()}_model.blend")) as (src, dst):
            dst.objects = list(src.objects)
        objects = dst.objects
    for o in objects:
        if o.type == "MESH" and o.name not in p["hide"]:
            scene.collection.objects.link(o)
    bpy.context.view_layer.update()
    # the model faces +Y; its right is +X. Azimuth 180 is face on, and less than that comes round to its right.
    azimuth = 180.0 - p["side"] * p["body"]
    yaw = -math.radians(p["side"] * p["turn"])            # about Z: +Y toward the camera's side
    spin = (Matrix.Rotation(yaw, 4, "Z") @ Matrix.Rotation(math.radians(p["nod"]), 4, "X")
            @ Matrix.Rotation(math.radians(p["tilt"]), 4, "Y"))
    turn = Matrix.Translation(NECK) @ spin @ Matrix.Translation(-NECK)
    for part in p["head"]:
        obj = bpy.data.objects[part]
        obj.matrix_world = turn @ obj.matrix_world
    rm.eevee(scene, *size)
    rm.sun_for(scene, azimuth)
    a = math.radians(azimuth)   # a fill from the camera itself: a fringe or a brim mustn't put the eyes in shade
    fill = bpy.data.objects.new("Fill", bpy.data.lights.new("Fill", "SUN"))
    fill.data.energy, fill.data.use_shadow = 1.1, False
    scene.collection.objects.link(fill)
    fill.rotation_euler = Vector((-math.sin(a), math.cos(a), -0.12)).to_track_quat("-Z", "Y").to_euler()
    path = out / f"_{name}.png"
    shot = rs.shoot(scene, path, azimuth, p["elevation"], p["centre"], p["span"])
    path.unlink()
    return shot


def contact(out: Path, only=()):
    """The heads alone, large and at the card's size, over a dark ground: to choose the angles."""
    tiles = [shoot_portrait(name, out) for name in (only or PORTRAITS)]
    page = rs.canvas(len(tiles) * 328 + 16, 376 + 124 + 40, (0.09, 0.09, 0.11))
    for i, shot in enumerate(tiles):
        rs.paste(page, rs.shrink(shot, 0.5), 16 + i * 328, 16)
        rs.paste(page, rs.shrink(shot, 76 / RENDER[0]), 16 + i * 328, 408)        # the lead's card at 2 pixels a point
        rs.paste(page, rs.shrink(shot, 38 / RENDER[0]), 16 + i * 328 + 92, 408)   # and at 1
    rs.save(page, out / "hud_contact.png")


RARITIES = ("Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical")


def shoot_unknown(out: Path, size=RENDER):
    """A Voidkin that isn't made yet: a head, a neck and a pair of shoulders, a little off square, as one pale violet
    shape against the frame's dark well, lit along its upper edges. No face, no costume, nobody's. It's drawn, not
    shot: a bare R6 body cropped to a portrait is a slab with a stub, and at the card's size it read as an empty
    frame. The shoulders end inside the frame and the neck is a step, so it's a person at 40 points."""
    w, h = size
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)

    def block(cx, cy, hw, hh, r):   # a rounded box's distance, in pixels of the render
        dx, dy = np.abs(xx - cx * w) - (hw * w - r), np.abs(yy - cy * h) - (hh * h - r)
        return np.hypot(np.maximum(dx, 0), np.maximum(dy, 0)) + np.minimum(np.maximum(dx, dy), 0) - r

    far = block(0.53, 0.345, 0.185, 0.165, 34.0)                 # the head, turned a touch to the near shoulder
    far = np.minimum(far, block(0.515, 0.55, 0.075, 0.07, 6.0))  # the neck
    far = np.minimum(far, block(0.49, 1.02, 0.41, 0.43, 46.0))   # the shoulders, running out of the frame's foot
    shot = np.zeros((h, w, 4), np.float32)
    shot[..., 3] = np.clip(0.5 - far, 0, 1)
    cover = shot[..., 3]
    edge = np.clip(cover - np.roll(cover, 10, axis=0), 0, 1)                      # its upper edges, lit from above
    edge = np.maximum(edge, 0.6 * np.clip(cover - np.roll(cover, 8, axis=1), 0, 1))  # and its left ones, less
    yy = np.linspace(0, 1, cover.shape[0], dtype=np.float32)[:, None, None]
    body = np.array(rs.rgb("#4A4766"), np.float32) * (1 - yy) + np.array(rs.rgb("#262437"), np.float32) * yy
    rim = np.array(rs.rgb("#A7A2CC"), np.float32)
    px = np.zeros_like(shot)
    px[..., :3] = body * (1 - edge[..., None]) + rim * edge[..., None]
    px[..., 3] = cover
    return px


def frame_name(rarity, small):
    return f"Frame{rarity}{'Small' if small else ''}"


def cut(shot, rarity, small, kit):
    """A portrait cut to its frame's mask, on the frame's own canvas: its opening is the frame's box less a point all
    round, and the portrait fills it."""
    name = frame_name(rarity, small)
    entry = kit["images"][name]
    pad = entry["pad"]
    w, h = entry["points"][0] - 2 * pad, entry["points"][1] - 2 * pad
    mask = rs.load(KIT / "masks" / f"{name}Mask.png")
    face = rs.shrink(shot, round((w - 2) * K) / shot.shape[1])
    x0, y1 = round((pad + 1) * K), round((pad + h - 1) * K)
    px = np.zeros_like(mask)
    px[y1 - face.shape[0]:y1, x0:x0 + face.shape[1]] = face
    px[..., 3] *= mask[..., 3]
    return px, entry


# --- the critical's sweep -----------------------------------------------------------------------------------------

SWEEP = (72.0, 24.0)    # points: drawn for a 28 point number, whose digits stand 20 high
SHEAR = 0.176           # the critical's slant, 10 degrees (research's table, round 2)
SWEEP_TINT = "#CC661F"  # burnt orange: the slice's white. Its tail is drawn darker, so the tint goes brown there
SWEEP_SEE = 0.4         # how see-through the game draws it (ImageTransparency): about 60% opaque
# Round 2's digits, for the sheet and the builder's Config: the gap between digits as a part of a digit's width, the
# gradient from the digits' head to their foot, the outline and its width in points at a 28 point number.
DIGITS = dict(gap=0.4, top="#FFF4D6", foot="#F2B43C", outline="#4E2C16", outlinePoints=1.0, slantDegrees=10)
SPACE = 1.24            # Blender's letter spacing that gives that gap in its own face


def sweep():
    """The mark under a critical number: one pull of a dry brush, level, leaning with the number. The brush lands
    loaded at the number's first digit, a square press with a ragged edge, and runs dry along the pull: its bristles
    part into long streaks and give out one by one, the middle ones last. No curl, no drop, no spatter, no point.
    A grey slice the game tints: white where the paint is thick, darker toward the dry tail."""
    w, h = SWEEP
    rng = np.random.default_rng(11)
    rows, cols = round(h * K), round(w * K)
    yy, xx = np.mgrid[0:rows, 0:cols]
    y = (yy + 0.5) / K
    x = (xx + 0.5) / K - SHEAR * (h / 2 - y)             # along the pull, the slant taken out
    u = (x - 4.0) / (w - 9.0)                            # 0 where the brush lands, 1 at the longest bristle's end
    half = 9.0                                           # the mark is 18 points high
    v = (y - h / 2) / half
    ease = lambda t: np.clip(t, 0, 1) ** 2 * (3 - 2 * np.clip(t, 0, 1))   # noqa: E731
    # each bristle is a level row: where it lands, where it gives out, how dry it is from the start
    row_v = v[:, 0]
    long = 1 - np.abs(np.clip(row_v + 0.12, -1, 1)) ** 2.2          # the longest a little above the middle
    wander = np.convolve(rng.random(rows + 8), np.ones(9) / 9, "valid")   # neighbours give out near each other
    end = 0.50 + 0.50 * long + 0.22 * (wander - 0.5) + 0.05 * (rng.random(rows) - 0.5)
    start = 0.07 * np.abs(row_v) ** 3 + 0.016 * rng.random(rows)
    dry = np.convolve(rng.random(rows + 2), (0.25, 0.5, 0.25), "valid")
    # the grain along each bristle: slow along the pull, fine across it
    coarse = rng.random((rows, 12))
    grain = np.stack([np.interp(np.linspace(0, 11, cols), np.arange(12), r) for r in coarse])
    grain = (grain + np.roll(grain, 1, 0) + np.roll(grain, -1, 0)) / 3
    grain = 0.5 * dry[:, None] + 0.5 * grain
    t = (u - start[:, None]) / (end[:, None] - start[:, None])
    load = 1.55 * (1 - np.clip(t, 0, 1)) ** 0.85         # past 1 the paint covers; under it the grain shows
    alpha = np.clip((load - grain) * 4.0 + 0.5, 0, 1)
    alpha *= np.clip(0.5 + (u - start[:, None]) * (w - 9.0) * K, 0, 1)    # the landing's edge
    alpha *= np.clip(0.5 + (1 - np.abs(v)) * half * K, 0, 1)              # the mark's upper and lower edge
    alpha *= t < 1
    value = 1.0 - 0.46 * ease(u / 0.85) - 0.07 * (grain - 0.5)
    px = np.zeros((rows, cols, 4), np.float32)
    px[..., :3] = np.clip(value, 0, 1)[..., None]
    px[..., 3] = alpha
    return px


# --- every image ---------------------------------------------------------------------------------------------------

def make(out: Path, only=()):
    kit = json.loads((KIT / "kit.json").read_text(encoding="utf-8"))
    images = out / "images"
    images.mkdir(parents=True, exist_ok=True)
    listing = {}
    if only:   # those alone: every other image and its listing stay as they are
        listing = json.loads((out / "hud_art.json").read_text(encoding="utf-8"))["images"]

    def keep(name, px, entry, use):
        rs.save(rs.bleed(px), images / f"{name}.png")
        listing[name] = dict(file=f"images/{name}.png", pixels=[px.shape[1], px.shape[0]], points=entry["points"],
                             pad=entry["pad"], use=use)

    for who in (only or PORTRAITS):
        rarity = voidkin_rarity(who)
        shot = shoot_portrait(who, out)
        rs.save(shot, out / f"{who}_uncut.png")
        for small in (False, True):
            px, entry = cut(shot, rarity, small, kit)
            keep(f"Portrait{who}{'Small' if small else ''}", px, entry,
                 f"{who}, cut to {frame_name(rarity, small)}: over its Back, under the frame, at the frame's own place and size")
    if only:
        (out / "hud_art.json").write_text(json.dumps(dict(pixelsPerPoint=K, images=listing), indent=1), encoding="utf-8")
        return
    shot = shoot_unknown(out)
    rs.save(shot, out / "Unknown_uncut.png")
    for rarity in RARITIES:
        for small in (False, True):
            px, entry = cut(shot, rarity, small, kit)
            keep(f"PortraitUnknown{rarity}{'Small' if small else ''}", px, entry,
                 f"a Voidkin with no portrait yet, cut to {frame_name(rarity, small)}")
    px = sweep()
    rs.save(px, images / "CritSweep.png")
    listing["CritSweep"] = dict(file="images/CritSweep.png", pixels=[px.shape[1], px.shape[0]], points=list(SWEEP), pad=0.0,
                                tint=SWEEP_TINT, shear=SHEAR, transparency=SWEEP_SEE, number=DIGITS,
                                use="behind a critical number, under its outline, under its leading half: its height the "
                                    "digits' own, its left edge a third of a digit before the first digit, its width 0.6 of "
                                    "the number's and never under three times its height; it stretches along, never up")
    (out / "hud_art.json").write_text(json.dumps(dict(pixelsPerPoint=K, images=listing), indent=1), encoding="utf-8")


# --- the review sheet -----------------------------------------------------------------------------------------------

LOOK = MODELS / "lanternrow"   # the merge's frames (tools/blender/lantern_row_look.py, `M` and `M far`): the street to read over
WHO = {"Rook": "sizing you up: the gauntlet's shoulder forward, chin down, a level look from under the brow",
       "Pip": "looking up from under a hat too big, head cocked, eager and a little unsure",
       "Lyric": "between songs: composed, chin a touch up, the headset to the camera",
       "Watt": "the quiet wall: the collar up to his nose, a level, steady look over it",
       "Kirra": "a quick sideways look back over the shoulder, a touch sly"}


def layers(page, x, y, names, scale):
    for name in names:
        folder = KIT / "images" if name.startswith("Frame") else LOADED
        rs.paste(page, rs.shrink(rs.load(folder / f"{name}.png"), scale), x, y)


def framed(page, x, y, portrait, rarity, small, scale):
    """A portrait in its frame, as the game lays it: the frame's Back, the portrait, the frame."""
    f = frame_name(rarity, small)
    layers(page, x, y, (f + "Back", portrait + ("Small" if small else ""), f), scale)


def crit_tile(ground, text="1,204"):
    """A critical number on its mark over a piece of the street, at 2 pixels a point: round 2's digits (wide apart, cream
    to gold, 10 degrees, a medium warm-brown outline), the mark under their leading half."""
    tile = ground.copy()
    h, w = tile.shape[:2]
    size = 28
    item = dict(x=w / ui.K / 2, y=h / ui.K / 2 - size * ui.CAP / 2, size=size, text=text, colour="#FFFFFF",
                align="CENTER", layer="number", shear=SHEAR, bold=0.012, space=SPACE)
    number = ui.text_layers(w, h, [item])["number"]
    cover = number[..., 3]
    filled, across = np.where(cover.any(1))[0], np.where(cover.any(0))[0]
    top, left, right = filled[0], across[0], across[-1]
    tall = round(size * ui.CAP * ui.K)                   # the digits' height; the comma hangs under it
    digit = (right - left) / (len(text) - 0.5 + (len(text) - 1) * DIGITS["gap"])    # a digit's width, the comma half
    swept = rs.shrink(rs.load(LOADED / "CritSweep.png"), tall / (SWEEP[1] * K))
    swept[..., :3] *= np.array(rs.rgb(SWEEP_TINT), np.float32)
    swept[..., 3] *= 1 - SWEEP_SEE
    rs.paste(tile, swept, round(left - digit / 3), top)
    ramp = np.clip((np.arange(h) - top) / tall, 0, 1)[:, None]
    number[..., :3] = (np.array(rs.rgb(DIGITS["top"]), np.float32) * (1 - ramp)
                       + np.array(rs.rgb(DIGITS["foot"]), np.float32) * ramp)[:, None, :]
    ui.over(tile, ui.c(DIGITS["outline"]), ui.spread(cover, round(DIGITS["outlinePoints"] * ui.K)))
    rs.paste(tile, number, 0, 0)
    return tile


LOADED = None


def sheet(out: Path):
    global LOADED
    LOADED = out / "images"
    street, far = rs.load(LOOK / "M_frame.png"), rs.load(LOOK / "M_far_frame.png")
    dark_num, bright_num = far[236:356, 20:320].copy(), street[86:206, 330:630].copy()
    tiles = [crit_tile(g) for g in (dark_num, bright_num)]            # before the page: text_layers resets the scene
    rs.OUT = out
    W, H = 1640, 1694
    page = rs.canvas(W, H, (0.075, 0.07, 0.085))
    ink, soft = "#F2ECE2", "#B9B2C4"
    text = [(24, 18, 26, "The HUD's own art: the launch portraits, the silhouette and the critical's stroke, round 2 (AR3, section 3).", ink),
            (24, 54, 15, "Each portrait is the Voidkin's own model, the body three-quarter on and the head turned back to the player, cut to its "
                         "rarity frame's mask. Shown in the frame as the game lays it: Back, portrait, frame.", soft)]
    y = 92
    for i, who in enumerate(PORTRAITS):
        rarity = voidkin_rarity(who)
        x = 24 + i * 536
        framed(page, x, y, f"Portrait{who}", rarity, False, 0.5)
        framed(page, x + 330, y + 10, f"Portrait{who}", rarity, True, 0.5)
        framed(page, x + 376, y + 220, f"Portrait{who}", rarity, True, 0.25)
        text.append((x + 60, y + 372, 15, f"{who}, {rarity}", ink))
        text.append((x + 60, y + 394, 12, WHO[who], soft))
    text.append((24, y + 424, 13, "Left of each: the full cut, 80 by 96 points at 2 pixels a point. Right: the small cut, the lead's card, 40 by 48 points "
                                  "at 2 pixels a point and at 1.", soft))
    y += 462
    text.append((24, y, 16, "At the lead's card's size over Lantern Row (the merge): its dark side and its bright end, at 2 pixels a point and at 1", ink))
    for j, ground in enumerate((far[190:350, 0:788], street[50:210, 86:874])):
        gx = 24 + j * 804
        rs.paste(page, ground.copy(), gx, y + 28)
        cast = [(f"Portrait{who}", voidkin_rarity(who)) for who in PORTRAITS] + [("PortraitUnknownUncommon", "Uncommon")]
        for i, (name, rarity) in enumerate(cast):
            framed(page, gx + 4 + i * 124, y + 8, name, rarity, True, 0.5)
            framed(page, gx + 520 + i * 62, y + 58, name, rarity, True, 0.25)
    y += 28 + 160 + 30
    text.append((24, y, 16, "A Voidkin that isn't made yet: one silhouette, cut to each rarity's frame", ink))
    framed(page, 24, y + 4, "PortraitUnknownRare", "Rare", False, 0.5)
    for i, rarity in enumerate(RARITIES):
        framed(page, 400 + i * 196, y + 50, f"PortraitUnknown{rarity}", rarity, True, 0.5)
        text.append((400 + i * 196 + 52, y + 256, 12, rarity, soft))
        framed(page, 400 + i * 196 + 46, y + 272, f"PortraitUnknown{rarity}", rarity, True, 0.25)
    y += 404 + 20
    text.append((24, y, 16, "The critical's stroke, round 2: one pull of a dry brush under the number's leading half, no taller than the digits. "
                            "The digits are round 2's: wide apart, cream to gold, 10 degrees, a medium warm-brown outline", ink))
    swept = rs.load(LOADED / "CritSweep.png")
    rs.paste(page, swept, 24, y + 40)
    text.append((24, y + 40 + 104, 12, "alone as it ships: a grey slice, 4 pixels a point", soft))
    amber = swept.copy()
    amber[..., :3] *= np.array(rs.rgb(SWEEP_TINT), np.float32)
    rs.paste(page, amber, 24, y + 40 + 130)
    text.append((24, y + 40 + 234, 12, f"tinted {SWEEP_TINT}, before the game makes it {round(SWEEP_SEE * 100)}% see-through", soft))
    for j, tile in enumerate(tiles):
        rs.paste(page, tile, 360 + j * 316, y + 40)
        rs.paste(page, rs.shrink(tile, 0.5), 360 + j * 316, y + 40 + 128)
        big = np.repeat(np.repeat(tile, 2, 0), 2, 1)[40:200, 60:540]
        rs.paste(page, big, 1000, y + 40 + j * 168)
    text.append((360, y + 40 + 196, 12, "at 2 pixels a point and at 1: the street's dark side, its bright end", soft))
    text.append((1490, y + 40, 12, "the same two,", soft))
    text.append((1490, y + 56, 12, "twice the size", soft))
    y += 40 + 336
    text.append((24, y, 16, "Each image alone at 64 px over dark, as moderation meets it", ink))
    names = [f"Portrait{who}" for who in PORTRAITS] + ["PortraitUnknownCommon"]
    for i, name in enumerate(names):
        px = rs.load(LOADED / f"{name}Small.png")
        pad = 26 * K
        rs.paste(page, rs.shrink(px[pad:-pad, pad:-pad], 64 / (px.shape[1] - 2 * pad)), 24 + i * 84, y + 28)
    rs.paste(page, rs.shrink(swept, 64 / swept.shape[1]), 24 + len(names) * 84, y + 50)
    rs.paste(page, rs.shrink(amber, 64 / swept.shape[1]), 24 + len(names) * 84 + 84, y + 50)
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "hud_art_sheet.png")


def review(out: Path, names):
    """The sheet for portraits added after the launch three, beside Rook's: each in its frame as the game lays it, the
    small cut at the lead's card's size over Lantern Row's dark side and its bright end, and each alone at 64 px over
    dark, as moderation meets it."""
    global LOADED
    LOADED = out / "images"
    street, far = rs.load(LOOK / "M_frame.png"), rs.load(LOOK / "M_far_frame.png")
    rs.OUT = out
    cast = ["Rook", *names]
    W, H = 24 + len(cast) * 536, 1060
    page = rs.canvas(W, H, (0.075, 0.07, 0.085))
    ink, soft = "#F2ECE2", "#B9B2C4"
    text = [(24, 18, 26, f"Portraits for {' and '.join(names)}, made as Rook's (AR3, section 3), Rook's beside them.", ink),
            (24, 54, 15, "Each is the Voidkin's own delivered model, cut to its rarity frame's mask, shown in the frame as the game "
                         "lays it: Back, portrait, frame.", soft)]
    y = 92
    for i, who in enumerate(cast):
        rarity = voidkin_rarity(who)
        x = 24 + i * 536
        framed(page, x, y, f"Portrait{who}", rarity, False, 0.5)
        framed(page, x + 330, y + 10, f"Portrait{who}", rarity, True, 0.5)
        framed(page, x + 376, y + 220, f"Portrait{who}", rarity, True, 0.25)
        text.append((x + 60, y + 372, 15, f"{who}, {rarity}", ink))
        text.append((x + 60, y + 394, 12, WHO[who], soft))
    y += 440
    text.append((24, y, 16, "The small cut at the lead's card's size over Lantern Row: its dark side and its bright end, at 2 pixels a point and at 1", ink))
    for j, ground in enumerate((far[190:350, 0:788], street[50:210, 86:874])):
        gy = y + 28 + j * 180
        rs.paste(page, ground.copy(), 24, gy)
        for i, who in enumerate(cast):
            framed(page, 28 + i * 124, gy - 20, f"Portrait{who}", voidkin_rarity(who), True, 0.5)
            framed(page, 524 + i * 62, gy + 30, f"Portrait{who}", voidkin_rarity(who), True, 0.25)
    y += 28 + 2 * 180 + 10
    text.append((24, y, 16, "Each alone at 64 px over dark, as moderation meets it", ink))
    for i, who in enumerate(names):
        px = rs.load(LOADED / f"Portrait{who}Small.png")
        pad = 26 * K
        rs.paste(page, rs.shrink(px[pad:-pad, pad:-pad], 64 / (px.shape[1] - 2 * pad)), 24 + i * 84, y + 28)
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / f"hud_portraits_{'_'.join(n.lower() for n in names)}.png")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    mode = args[0] if args else "contact"
    names = [a for a in args[1:] if a in PORTRAITS]
    if mode == "contact":
        contact(out, names)
    elif mode == "make":
        make(out, names)
    elif mode == "sheet":
        sheet(out)
    elif mode == "review":
        review(out, names)


if __name__ == "__main__":
    main()
