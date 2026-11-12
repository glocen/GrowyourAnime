"""AR3 section 3, the HUD's own art (docs/asset-requests.md; docs/ui.md, "The HUD, in the world"): each launch
Voidkin's portrait for the lead's card, cut to its rarity frame's mask; one silhouette for a Voidkin that isn't made
yet; and the swept stroke behind a critical number.

A portrait is the Voidkin's own model, head and shoulders, the body three-quarter on and the head turned back to the
player, so the eyes meet whoever holds the phone. The engine can't clip a picture to a cut corner, so each is cut here
to its frame's mask (the UI kit's, `build/handoff/UI/kit/masks/`), on the frame's own canvas: the builder lays it
where the frame goes, between the frame's Back and the frame.

Run, each a headless Blender job:
  ... --python tools/blender/hud_art.py -- <out> contact     the heads alone, to choose the angles
  ... --python tools/blender/hud_art.py -- <out> make        every image, into <out>/images
  ... --python tools/blender/hud_art.py -- <out> sheet       the review sheet, from the images
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
}


def voidkin_rarity(name):
    """A Voidkin's rarity, read from the game's own table."""
    text = (REPO / "src" / "shared" / "Definitions" / "Voidkin.luau").read_text(encoding="utf-8")
    found = re.search(r'Name = "%s", Rarity = "(\w+)"' % name, text)
    if not found:
        raise SystemExit(f"{name} isn't in Definitions.Voidkin")
    return found.group(1)


def shoot_portrait(name, out: Path, size=RENDER):
    """One Voidkin's head and shoulders, on transparency."""
    p = PORTRAITS[name]
    scene = bl.reset_scene()
    scene.world = bpy.data.worlds.new("Portrait")
    with bpy.data.libraries.load(str(MODELS / name.lower() / "model" / f"{name.lower()}_model.blend")) as (src, dst):
        dst.objects = list(src.objects)
    for o in dst.objects:
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


def contact(out: Path):
    """The heads alone, large and at the card's size, over a dark ground: to choose the angles."""
    tiles = [shoot_portrait(name, out) for name in PORTRAITS]
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

SWEEP = (112.0, 56.0)   # points: drawn for a 28 point number of five characters; it stretches along with a longer one
SHEAR = 0.22            # the numbers' own slant (ui_sheet.numbers)
# Each streak: its middle line (points down the canvas), half its thickness, where it starts and ends along the canvas.
STREAKS = ((30.0, 11.0, 0.08, 0.90), (11.5, 3.2, 0.34, 0.99), (47.5, 2.6, 0.02, 0.70), (18.6, 1.0, 0.12, 0.60),
           (43.0, 0.9, 0.40, 0.95))
SLITS = ((-4.2, 0.75), (2.4, 0.55), (6.6, 0.85))  # dry-brush gaps in the wide streak: offset from its middle, how far along


def sweep():
    """The stroke behind a critical number: speed lines, not a cut. Five straight, level, parallel streaks leaning with
    the number, each thin and faint at its tail and square at its head, the wide one split at the tail by dry gaps.
    Nothing curved, nothing tapered to a point at the head, no drop, no spatter. A grey slice the game tints."""
    w, h = SWEEP
    yy, xx = np.mgrid[0:round(h * K), 0:round(w * K)]
    y = (yy + 0.5) / K
    u = ((xx + 0.5) / K - SHEAR * (h / 2 - y)) / w       # along the canvas, the slant taken out
    ease = lambda t: np.clip(t, 0, 1) ** 2 * (3 - 2 * np.clip(t, 0, 1))
    value = np.zeros(y.shape, np.float32)
    alpha = np.zeros(y.shape, np.float32)
    for i, (yc, half, u0, u1) in enumerate(STREAKS):
        t = (u - u0) / (u1 - u0)
        d = np.abs(y - yc) - half * (0.22 + 0.78 * ease(t / 0.55))
        a = np.clip(0.5 - d * K, 0, 1) * ease(t / 0.5) * np.clip(0.5 + t * (u1 - u0) * w * K, 0, 1) \
            * np.clip(0.5 + (1 - t) * (u1 - u0) * w * K, 0, 1)
        if i == 0:
            for off, upto in SLITS:
                gap = np.abs(y - yc - off) - 0.75 * (1 - ease(t / upto))
                a *= 1 - np.clip(0.5 - gap * K, 0, 1) * (t < upto)
        v = 0.66 + 0.34 * ease(t)                        # brighter toward the head
        value = np.where(a > alpha, v, value)
        alpha = np.maximum(alpha, a)
    px = np.zeros((*y.shape, 4), np.float32)
    px[..., :3] = value[..., None]
    px[..., 3] = alpha
    return px


# --- every image ---------------------------------------------------------------------------------------------------

def make(out: Path):
    kit = json.loads((KIT / "kit.json").read_text(encoding="utf-8"))
    images = out / "images"
    images.mkdir(parents=True, exist_ok=True)
    listing = {}

    def keep(name, px, entry, use):
        rs.save(px, images / f"{name}.png")
        listing[name] = dict(file=f"images/{name}.png", pixels=[px.shape[1], px.shape[0]], points=entry["points"],
                             pad=entry["pad"], use=use)

    for who in PORTRAITS:
        rarity = voidkin_rarity(who)
        shot = shoot_portrait(who, out)
        rs.save(shot, out / f"{who}_uncut.png")
        for small in (False, True):
            px, entry = cut(shot, rarity, small, kit)
            keep(f"Portrait{who}{'Small' if small else ''}", px, entry,
                 f"{who}, cut to {frame_name(rarity, small)}: over its Back, under the frame, at the frame's own place and size")
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
                                tint=SWEEP_TINT, shear=SHEAR,
                                use="behind a critical number, under its stroke: centred on the number, its height twice the "
                                    "number's size, its width the number's width and a half; it stretches along, never up")
    (out / "hud_art.json").write_text(json.dumps(dict(pixelsPerPoint=K, images=listing), indent=1), encoding="utf-8")


SWEEP_TINT = "#E8862A"  # amber: under the number's gold and well clear of red


# --- the review sheet -----------------------------------------------------------------------------------------------

LOOK = MODELS / "lanternrow"   # the merge's frames (tools/blender/lantern_row_look.py, `M` and `M far`): the street to read over
WHO = {"Rook": "sizing you up: the gauntlet's shoulder forward, chin down, a level look from under the brow",
       "Pip": "looking up from under a hat too big, head cocked, eager and a little unsure",
       "Lyric": "between songs: composed, chin a touch up, the headset to the camera"}


def layers(page, x, y, names, scale):
    for name in names:
        folder = KIT / "images" if name.startswith("Frame") else LOADED
        rs.paste(page, rs.shrink(rs.load(folder / f"{name}.png"), scale), x, y)


def framed(page, x, y, portrait, rarity, small, scale):
    """A portrait in its frame, as the game lays it: the frame's Back, the portrait, the frame."""
    f = frame_name(rarity, small)
    layers(page, x, y, (f + "Back", portrait + ("Small" if small else ""), f), scale)


def crit_tile(ground, text="1,204"):
    """A critical number on its sweep over a piece of the street, at 2 pixels a point (ui_sheet's own number)."""
    tile = ground.copy()
    h, w = tile.shape[:2]
    swept = rs.shrink(rs.load(LOADED / "CritSweep.png"), ui.K / K)
    swept[..., :3] *= np.array(rs.rgb(SWEEP_TINT), np.float32)
    rs.paste(tile, swept, (w - swept.shape[1]) // 2, (h - swept.shape[0]) // 2)
    item = dict(x=w / ui.K / 2, y=h / ui.K / 2 - 28 * ui.CAP / 2, size=28, text=text, colour=ui.NUMBER["critical"],
                align="CENTER", layer="number", shear=SHEAR, bold=0.012)
    number = ui.text_layers(w, h, [item])["number"]
    ui.over(tile, ui.c(ui.STROKE), ui.spread(number[..., 3], 3))
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
    W, H = 1640, 1612
    page = rs.canvas(W, H, (0.075, 0.07, 0.085))
    ink, soft = "#F2ECE2", "#B9B2C4"
    text = [(24, 18, 26, "The HUD's own art: the launch portraits, the silhouette and the critical's sweep (AR3, section 3).", ink),
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
    text.append((24, y, 16, "The critical's sweep: speed lines behind the number. Alone as it ships (a grey slice, 4 pixels a point); tinted amber under "
                            "a critical at 2 pixels a point and at 1, over the street's dark side and its bright end", ink))
    swept = rs.load(LOADED / "CritSweep.png")
    rs.paste(page, swept, 24, y + 34)
    for j, tile in enumerate(tiles):
        rs.paste(page, tile, 500 + j * 316, y + 34)
        rs.paste(page, rs.shrink(tile, 0.5), 500 + j * 316, y + 34 + 128)
    amber = swept.copy()
    amber[..., :3] *= np.array(rs.rgb(SWEEP_TINT), np.float32)
    rs.paste(page, amber, 1150, y + 34)
    text.append((1150, y + 34 + 230, 12, f"tinted {SWEEP_TINT}, alone", soft))
    y += 34 + 262
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


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    mode = args[0] if args else "contact"
    if mode == "contact":
        contact(out)
    elif mode == "make":
        make(out)
    elif mode == "sheet":
        sheet(out)


if __name__ == "__main__":
    main()
