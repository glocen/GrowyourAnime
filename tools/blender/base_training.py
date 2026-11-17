"""AR35: the Training machine's Stages II and III, two directions for how it grows, in grey beside Stage I
(docs/asset-requests.md, AR35). The machine takes the base's level: Stage I at level 1, II at 2, III at 3.

Stage I is the machine as it stands (base_machines.training, training_crown): the sparring stone on its deck, its
reticle, the spark over it, the crown turning round the spark, and the pad out in front where the Voidkin trains.

  A, the Weighted Crown   the crown, the machine's moving part, carries more: its flat ring widens and its weights go
                          from four to six to eight, larger and taller. Flat, so from the court it is a bar, as at I.
  B, the Sparring Ring    lesser fangs of void stone stand at the pad's sides, an uneven arc open to the gate and
                          stepping down toward it, each with a vein of the void's light up its edge toward the pad.

The review: each stage in the yard at base level 3, a Voidkin's size on the pad, from a player in the court turned to
the machine, on the way to the back bay, head-on, from both sides, from behind and three-quarter, cut small and in
black. Two passes, so the page fits in memory beside Studio: the shots, then each direction's sheet from disk.
blender.exe -b --factory-startup --python-exit-code 1 --python tools/blender/base_training.py -- <abs out_dir> [fast]
blender.exe -b --factory-startup --python-exit-code 1 --python tools/blender/base_training.py -- <abs out_dir> sheet
"""

import json
import math
import sys
import textwrap
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_machines as bm  # noqa: E402
import lantern_row_kit as kit  # noqa: E402
from base_mill import Mesh, at, put  # noqa: E402

CROWN = bm.CROWN
GREY = {"steel": "concrete", "girder": "concrete", "abyss": "concrete", "yellow": "concrete", "copper": "concrete",
        "bone": "ceramic"}
DIRECTIONS = {"A": "the Weighted Crown", "B": "the Sparring Ring"}


class Swap:
    """While it's open, every swatch a shape asks for is drawn in its stand-in."""

    def __init__(self, table):
        self.table = table

    def __enter__(self):
        self.own = kit.sw_uv
        kit.sw_uv = lambda name, occ, t: self.own(self.table.get(name, name), occ, t)

    def __exit__(self, *_):
        kit.sw_uv = self.own


# --- A, the Weighted Crown ------------------------------------------------------------------------------------------------

# a stage's crown: its ring's inner and outer radius, its weights, how far out they float, their half width and height.
# A weight is a slim crystal, upright, 3 times as tall as it is wide at least (the content check, 18:50), and it
# straddles the ring, its tip over the spark's
CROWNS = {2: dict(ring=(2.8, 3.25), weights=6, out=4.1, half=0.42, high=2.6),
          3: dict(ring=(3.3, 3.75), weights=8, out=4.6, half=0.45, high=3.2)}


def crown(stage):
    """A stage's crown, built round its own middle as TrainingCrown is: a flat ring of void stone, two marks of the
    void's light on its rim for each weight, and the weights, upright shards of void stone, floating round it."""
    c = CROWNS[stage]
    m = Mesh()
    r0, r1 = c["ring"]
    bm.hoop(m, (0, 0, 0), r0, r1, 0.34, 8 + 4 * stage, "abyss", lying=True)
    marks = 2 * c["weights"]
    for k in range(marks):
        a = math.tau * k / marks
        m.box((0.3, 0.5, 0.42), ((r1 + 0.02) * math.cos(a), (r1 + 0.02) * math.sin(a), 0), "void", rot=(0.0, 0.0, a))
    for k in range(c["weights"]):
        a = math.tau * (k + 0.5) / c["weights"]
        bm.shard(m, (c["out"] * math.cos(a), c["out"] * math.sin(a), 0.1), c["half"], c["high"], "abyss", lean=0.35,
                 ink=True)
    return m


def weighted(stage):
    m = Mesh()
    put(m, bm.training().mesh, at(0, 0, 0))
    put(m, crown(stage), at(0, 0, CROWN))
    return m


# --- B, the Sparring Ring -------------------------------------------------------------------------------------------------

# the fangs, in the order they come: across, toward the gate (the pad's middle is bm.TRAINEE), high, half width at the
# foot. An uneven arc at the pad's sides, inside the footprint's 6.2, stepping down toward the gate and open there;
# never a mirror pair, in height, depth or width (the content check, 18:50)
FANGS = [(-2.62, 4.7, 4.3, 0.4), (2.66, 5.3, 3.7, 0.36), (-2.68, 7.2, 3.1, 0.34), (2.7, 7.6, 2.6, 0.3)]
FANGS_AT = {2: 2, 3: 4}


def fang(m, x, y, high, half):
    """A lesser sparring stone: a straight fang of void stone rooted on its own on the floor, a chiselled tip, leaning
    a little out from the pad, an edge toward it, and a straight vein of the void's light up that edge, of even width,
    stopping short of the tip."""
    out = 1.0 if x > 0 else -1.0
    lean = 0.25 * out

    def on(t):
        return (x + lean * t, y, high * t)

    def width(t):
        if t < 0.55:
            return half - 0.2 * half * t / 0.55
        return 0.8 * half + (0.05 - 0.8 * half) * (t - 0.55) / 0.45

    bm.horn(m, [on(0.0), on(0.55), on(1.0)], [width(0.0), width(0.55), width(1.0)], "abyss", flat=(0.0, 1.0, 0.0),
            deep=1.15)
    steps = (0.12, 0.45, 0.78)
    bm.vein(m, [on(t) for t in steps], [width(t) for t in steps], (x - out * 50.0, y, high / 2), r=0.07)


def sparring(stage):
    m = Mesh()
    put(m, bm.training().mesh, at(0, 0, 0))
    put(m, bm.training_crown().mesh, at(0, 0, CROWN))
    for x, y, high, half in FANGS[:FANGS_AT[stage]]:
        fang(m, x, y, high, half)
    return m


def stage_one():
    m = Mesh()
    put(m, bm.training().mesh, at(0, 0, 0))
    put(m, bm.training_crown().mesh, at(0, 0, CROWN))
    return m


def build():
    made = {"I": stage_one()}
    for key, body in (("A", weighted), ("B", sparring)):
        for stage in (2, 3):
            with Swap(GREY):
                made[f"{key}{'I' * stage}"] = body(stage)
    return made


# --- the review: each stage in the yard ---------------------------------------------------------------------------------

FULL_VIEWS = ("front", "side", "three")                     # at their own size
CUT_VIEWS = ("court", "front", "side", "far", "back", "three", "high")   # cut small and in black


def toward(at_, target):
    """The game's camera behind a player at `at_` (across, in), turned to `target`: the start zoom and pitch."""
    import lantern_row_look as look
    from mathutils import Vector
    pitch, focus = math.radians(20.0), Vector((at_[0], -at_[1], 3.0 + look.FOCUS))
    flat = Vector((target[0] - at_[0], -(target[1] - at_[1]), 0.0)).normalized()
    eye = focus - flat * math.cos(pitch) * look.ZOOM + Vector((0, 0, 1)) * math.sin(pitch) * look.ZOOM
    return tuple(eye), tuple(focus)


def review(out, fast):
    """The shots, each saved with its shape's silhouette and its box on the picture (training_review.json)."""
    import bpy
    from bpy_extras.object_utils import world_to_camera_view
    import base_kit as base
    import base_plan as plan
    import blcommon as bl
    import lantern_row_look as look
    import rook_sheet as rs

    level, spot = 3, base.TRAINING
    made = plan.machines
    plan.machines = lambda lv=1: [row for row in made(lv) if row[0] not in ("Training", "TrainingCrown")]
    d = look.DIRECTIONS["M"]
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1], azimuth=d.get("glow_az", 0.0),
                    away=look.srgb(d["fog_away"]) if "fog_away" in d else None)
    scene = bl.reset_scene()
    base.write_pictures(out / "maps")
    yard = plan.Yard(scene, level, out / "maps")
    yard.plot(0.0, 1)
    yard.plot(plan.STRIP, -1)
    yard.kit.block("Strip", (3 * plan.PLOT, plan.STRIP, 0.4), (0, plan.STRIP / 2, -0.22), yard.stone)
    yard.kit.block("Ground", (5 * plan.PLOT, 4 * plan.PLOT, 0.4), (0, plan.STRIP / 2, -0.3), yard.flat["ground"])
    x, inward = spot                                        # the yard stands a Voidkin's size on the pad, training
    for obj in yard.kit.pieces:
        if obj.name.startswith(("PowerSpan", "Court", "Yard", "Wings")):
            obj.visible_shadow = False
    look.sky(scene, d)
    look.sun(scene, d)
    r = scene.render
    for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            r.engine = engine
            break
        except TypeError:
            continue
    r.resolution_x, r.resolution_y, r.resolution_percentage = *look.SIZE, 100
    scene.view_settings.view_transform = "Standard"
    scene.eevee.taa_render_samples = 8 if fast else 32
    for attr, val in (("use_shadows", True), ("shadow_ray_count", 2), ("use_raytracing", False)):
        try:
            setattr(scene.eevee, attr, val)
        except AttributeError:
            pass
    kit_mat = yard.stock.mats["Kit"]

    mid = (x, -inward + 3.0, 5.5)                           # the machine's middle, the stone to the pad
    views = {"court": toward((-16.0, 36.0), spot),          # a player at the court's back, turned to it
             "way": toward((-43.0, 56.0), spot),            # on the way to the left side's back bay
             "front": ((x, mid[1] + 20.0, 7.5), mid),       # head-on from the gate's side, the pad nearest
             "side": ((x + 18.0, mid[1], 7.5), mid),        # from the generator's side
             "far": ((x - 18.0, mid[1], 7.5), mid),         # from the side wall's side
             "back": ((x, -inward - 12.0, 6.5), mid),       # from behind the stone
             "three": ((x + 13.0, mid[1] + 13.0, 7.5), mid),
             "high": ((x + 9.75, mid[1] + 9.75, mid[2] + 11.6), mid)}   # 40 degrees down, 18 away: a dial, not an eye
    w, h = look.SIZE
    boxes, tris = {}, {}

    def silhouette(obj, path):
        """The stage alone in the workbench, its shape as the picture's alpha (the sheet draws it black)."""
        hidden = [o for o in scene.objects if o is not obj and o.type == "MESH" and not o.hide_render]
        for o in hidden:
            o.hide_render = True
        engine = r.engine
        r.engine, r.film_transparent = "BLENDER_WORKBENCH", True
        r.image_settings.file_format, r.image_settings.color_mode = "PNG", "RGBA"
        r.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        r.engine, r.film_transparent = engine, False
        for o in hidden:
            o.hide_render = False

    for key, mesh in build().items():
        tris[key] = mesh.whole().tris()
        data = mesh.whole().to_object(f"Training{key}", kit_mat)
        obj = bpy.data.objects.new(f"Training{key}", data)
        obj.location = (x, -inward, 0.0)
        scene.collection.objects.link(obj)
        bpy.context.view_layer.update()
        for name, (eye, target) in views.items():
            scene.camera = plan.camera(scene, f"Cam{key}{name}", eye, target)
            path = out / f"training_{key}_{name}.png"
            rs.save(look.finish(look.render_linear(scene, path.with_suffix(".exr")), d), path)
            path.with_suffix(".exr").unlink(missing_ok=True)
            if name in CUT_VIEWS:
                pts = [world_to_camera_view(scene, scene.camera, obj.matrix_world @ v.co) for v in obj.data.vertices]
                boxes[f"{key} {name}"] = (min(p.x for p in pts) * w, min((1 - p.y) for p in pts) * h,
                                          max(p.x for p in pts) * w, max((1 - p.y) for p in pts) * h)
                silhouette(obj, out / f"black_{key}_{name}.png")
        bpy.data.objects.remove(obj)
        bpy.data.meshes.remove(data)
    (out / "training_review.json").write_text(json.dumps(dict(boxes=boxes, tris=tris)), encoding="utf-8")


NOTES = {
    "A": "The crown carries more. The stone, its reticle, the spark and the pad stay as at Stage I. At Stage II the "
         "crown's flat ring widens to 3.25 and carries six weights, upright crystals of void stone, slimmer and taller "
         "than Stage I's four and straddling the ring, with twelve marks of the void's light on its rim; at Stage III "
         "it widens to 3.75 with eight weights and sixteen marks. It stays flat, so from the court it is a bar, as at "
         "Stage I: 7.6 across at its weights, then 9.0, then 10.1. The spark is Stage I's. Each stage's crown is a "
         "piece of its own that replaces Stage I's and turns as it does while a Voidkin trains.",
    "B": "Fangs rise round the Voidkin. The stone, the crown and the pad stay as at Stage I. At Stage II two lesser "
         "sparring stones of void stone stand on the floor at the pad's sides, the left one 4.3 high a little behind "
         "the pad's middle, the right one 3.7 nearer it; at Stage III two more beside its front half, 3.1 and 2.6, so "
         "the arc steps down toward the gate and is open there. Each is a straight fang with a chiselled tip leaning a "
         "little out, an edge toward the pad with a vein of the void's light up it, stopping short of the tip. Nothing "
         "joins them, and each stands under the Voidkin's head.",
}
SHARED = ("Both: the footprint stays inside 6.2 by 11.2. A Voidkin's size stands on the pad, training. Stage I in the "
          "base kit's colours; Stages II and III in grey blocks with the void's light lit, in the yard at base level 3 "
          "under the place's dusk, rendered in Blender; nothing is seen in Studio.")


def sheet(out, key):
    """A direction's review sheet from the shots on disk, in a Blender of its own: the yard's scene is gone, so the
    page and its text fit in memory beside Studio."""
    import numpy as np
    import lantern_row_look as look
    import rook_sheet as rs
    import ui_sheet as ui

    saved = json.loads((out / "training_review.json").read_text(encoding="utf-8"))
    boxes, tris = {tuple(k.split(" ")): v for k, v in saved["boxes"].items()}, saved["tris"]
    w, h = look.SIZE
    keys = ("I", f"{key}II", f"{key}III")

    def shot(k, name):
        return rs.load(out / f"training_{k}_{name}.png")

    def blackened(k, name):
        px = rs.load(out / f"black_{k}_{name}.png")
        ink = np.ones_like(px)
        ink[..., :3] = 1.0 - px[..., 3:4]
        return ink

    def union(name):
        b = [boxes[(k, name)] for k in keys]
        return tuple(int(v) for v in (max(min(q[0] for q in b) - 8, 0), max(min(q[1] for q in b) - 8, 0),
                                      min(max(q[2] for q in b) + 8, w), min(max(q[3] for q in b) + 8, h)))

    def crop(px, box):
        return px[box[1]:box[3], box[0]:box[2]]

    unions = {name: union(name) for name in CUT_VIEWS}
    fulls = {name: [crop(shot(k, name), unions[name]) for k in keys] for name in CUT_VIEWS}
    titles = ("Stage I, base level 1, as it stands", "Stage II, base level 2", "Stage III, base level 3")
    said = {"court": "from the court, as the player sees it", "front": "head-on from the gate's side, 20 away",
            "side": "from the generator's side, 18 away", "far": "from the side wall's side, 18 away",
            "back": "from behind the stone, 12 away", "three": "three-quarter, from the front and the generator's side",
            "high": "from above, 40 degrees down, three-quarter"}
    notes = [NOTES[key], SHARED + " Triangles, a stage whole, before the drawn edge's hull: "
             + ", ".join(f"Stage {k if k == 'I' else k[1:]} {tris[k]:,}" for k in keys) + "."]
    lines = [ln for n in notes for ln in textwrap.wrap(n, 230)]
    gap = 16
    cw, ch = round(w * 2 / 3), round(h * 2 / 3)
    small = 26 + 64 + gap + 128 + gap + 20
    widths = [sum(px.shape[1] for px in fulls[n]) + 4 * gap for n in FULL_VIEWS]
    cuts = [3 * (2 * round(128 * px.shape[1] / px.shape[0]) + 8 + 2 * gap) + 2 * gap
            for n in CUT_VIEWS for px in fulls[n][:1]]
    width = max(3 * cw + 4 * gap, *widths, *cuts, 1300)
    height = 48 + 2 * (ch + 34) + sum(max(px.shape[0] for px in fulls[n]) + 42 for n in FULL_VIEWS) \
        + len(CUT_VIEWS) * small + 34 + len(lines) * 19 + 24
    ui.K = 1                                               # a point a pixel: the sheet is laid out in pixels
    page = ui.Sheet(width, height, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 14, 20, f"Grow your Anime, the Training machine's stages: {key}, {DIRECTIONS[key]} (AR35)", "#EDE6D6",
           bold=0.2)
    y = 48
    for name, caption in (("court", "a player at the court's back turned to it, at a phone's 640 by 360"),
                          ("way", "a player between the left side's bays, on the way to the back one, turned to it")):
        for i, k in enumerate(keys):
            x0 = gap + i * (cw + gap)
            t.text(x0, y, 14, f"{titles[i]}: {caption}" if i == 0 else titles[i], "#B4AC9C")
            rs.paste(page.px, rs.shrink(shot(k, name), 2 / 3), x0, y + 22)
        y += ch + 34
    for name in FULL_VIEWS:
        t.text(gap, y, 14, f"{said[name]}, at its own size on a 960 by 540", "#B4AC9C")
        x0 = gap
        for px in fulls[name]:
            rs.paste(page.px, px, x0, y + 22)
            x0 += px.shape[1] + gap
        y += max(px.shape[0] for px in fulls[name]) + 42
    for name in CUT_VIEWS:
        t.text(gap, y, 14, f"{said[name]}: cut at one scale for the three, 64 and 128 px tall over the dark, and in "
               f"black", "#B4AC9C")
        x0 = gap
        for i, k in enumerate(keys):
            left, tall = x0, fulls[name][i].shape[0]
            ink = crop(blackened(k, name), unions[name])
            for px in (rs.shrink(fulls[name][i], 64 / tall), rs.shrink(ink, 64 / tall)):
                rs.paste(page.px, px, x0, y + 26)
                x0 += px.shape[1] + 8
            x0 = left
            for px in (rs.shrink(fulls[name][i], 128 / tall), rs.shrink(ink, 128 / tall)):
                rs.paste(page.px, px, x0, y + 26 + 64 + gap)
                x0 += px.shape[1] + 8
            t.text(left, y + 26 + 64 + 128 + 2 * gap - 6, 13, titles[i].split(",")[0], "#EDE6D6")
            x0 += 2 * gap
        y += small
    y += 14
    for i, ln in enumerate(lines):
        t.text(gap, y + i * 19, 14, ln, "#B4AC9C")
    for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
        rs.paste(page.px, layer, 0, 0)
    rs.save(page.px, out / f"training_{key}.png")
    print("triangles:", {k: tris[k] for k in keys})


def main():
    import blcommon as bl
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    if "sheet" in args:
        for key in DIRECTIONS:
            sheet(out, key)
    else:
        review(out, "fast" in args)


if __name__ == "__main__":
    main()
