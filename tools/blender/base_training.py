"""AR35: the Training machine's Stages II and III, the Weighted Crown, as base kit pieces (docs/asset-requests.md,
AR35; research's pick of A). The machine takes the base's level: Stage I at level 1, II at 2, III at 3.

The stone, its reticle, the spark and the pad stay Stage I's (base_machines.training) at every stage. The crown, the
machine's moving part, carries more: TrainingCrown2 and TrainingCrown3 each replace TrainingCrown at its place and turn
as it does. Every stage's crown, Stage I's included, is a flat band of void stone with short crystals set through it
and tall crystals standing near the spark, so its top line rises to its middle from every side while it turns: a
crown, never weights at a bar's ends (research's class on the pick, 2026-11-17, held at Stage I too on its pass). The
family's numbers and shape are base_machines.CROWNS and crown(); this module makes Stages II and III its pieces.

Not run by itself for the kit: base_kit.py takes PIECES into its own, base_plan.py the swap's table. Run, it renders the
review: each stage in the yard at base level 3, in two passes so the page fits in memory beside Studio:
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

Piece = kit.Piece
CROWN = bm.CROWN
TURNED = {1: 90.0, 2: 45.0, 3: 30.0}   # the review's second turn of each crown: its tall crystals at the other heading


# --- the kit's pieces and the swap's table ------------------------------------------------------------------------------

def crown_piece(stage):
    def make():
        across, tip = bm.crown_size(stage)
        n = bm.CROWNS[stage]["rim"][0]
        count = bm.CROWNS[stage]["core"][0]
        return Piece(f"TrainingCrown{stage}", bm.crown(stage),
                     note=f"Stage {'II' if stage == 2 else 'III'}'s crown, base level {stage}, in place of "
                          f"TrainingCrown: its origin is its middle, floating {CROWN:g} up at the Training machine's "
                          f"middle round the stone's spark. A band of void stone with {n} short crystals set through "
                          f"it and {2 * n} marks of the void's light, and {count} tall crystals near the spark, their "
                          f"tips {tip:.2f} over its middle. {across:.1f} across. It turns about its own upright while "
                          f"a Voidkin trains, still when none does, as TrainingCrown does. Look only")
    return make


def stages():
    """The swap's table: each stage's pieces at the Training machine's place (across, toward the gate, up), and how
    each moves."""
    table = {}
    for stage in (1, 2, 3):
        table[str(stage)] = dict(pieces=[
            dict(piece="Training", at=[0.0, 0.0, 0.0], moves="still"),
            dict(piece="TrainingCrown" if stage == 1 else f"TrainingCrown{stage}", at=[0.0, 0.0, CROWN],
                 moves="turns")])
    return table


def tables():
    return dict(trainingStages=dict(
        note="AR35: the Training machine's three stages, the Weighted Crown, the swap's table. The machine has no level "
             "of its own, so it takes the stage of the base's level (Stage I at 1, II at 2, III at 3). Every place is "
             "in the machine's own frame, turn 0: `across`, `along` toward the gate, `up` from its floor. The stone "
             "(Training) is the same at every stage; a stage's crown replaces the one before's at the same place. "
             "`moves`: still; turns, about the crown's own upright while a Voidkin trains, still when none does, at "
             "TrainingCrown's rate and sign (Config.World.Grey.Training.Crown). The game picks a piece's axis (Y) "
             "and its rate by its Piece being TrainingCrown; TrainingCrown2 and TrainingCrown3 take both.",
        stages=stages()))


PIECES = {"TrainingCrown2": crown_piece(2), "TrainingCrown3": crown_piece(3)}


def whole(stage, turn=0.0):
    """A stage whole, every piece at its table's place, the crown turned `turn` degrees about its upright: for the
    review."""
    from mathutils import Matrix
    made = {"Training": bm.training().mesh, "TrainingCrown": bm.training_crown().mesh,
            **{name: bm.crown(int(name[-1])) for name in PIECES}}
    m = Mesh()
    for row in stages()[str(stage)]["pieces"]:
        turned = Matrix.Rotation(math.radians(turn), 4, "Z") if row["moves"] == "turns" else Matrix()
        put(m, made[row["piece"]], at(*row["at"]) @ turned)
    return m


# --- the review: each stage in the yard ---------------------------------------------------------------------------------

FULL_VIEWS = ("front", "side", "three")                                  # at their own size
CUT_VIEWS = ("court", "front", "side", "sideturned", "far", "back", "backturned", "three", "high")   # cut small, in black
SECOND = {"sideturned": "side", "backturned": "back"}                    # the crown at its second turn, from these


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
        if obj.name.startswith(("PowerSpan", "Floor")):
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
             "high": ((x + 9.75, mid[1] + 9.75, mid[2] + 11.6), mid)}   # 40 degrees down, 18 away
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

    for key, stage in (("I", 1), ("II", 2), ("III", 3)):
        for turn, shots in ((0.0, {n: v for n, v in views.items()}),
                            (TURNED[stage], {n: views[v] for n, v in SECOND.items()})):
            mesh = whole(stage, turn)
            tris[key] = mesh.whole().tris()
            data = mesh.whole().to_object(f"Training{key}", kit_mat)
            obj = bpy.data.objects.new(f"Training{key}", data)
            obj.location = (x, -inward, 0.0)
            scene.collection.objects.link(obj)
            bpy.context.view_layer.update()
            for name, (eye, target) in shots.items():
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


def sheet(out):
    """The review sheet from the shots on disk, in a Blender of its own: the yard's scene is gone, so the page and its
    text fit in memory beside Studio."""
    import numpy as np
    import lantern_row_look as look
    import rook_sheet as rs
    import ui_sheet as ui

    saved = json.loads((out / "training_review.json").read_text(encoding="utf-8"))
    boxes, tris = {tuple(k.split(" ")): v for k, v in saved["boxes"].items()}, saved["tris"]
    w, h = look.SIZE
    keys = ("I", "II", "III")

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
    titles = ("Stage I, base level 1, its crown remade", "Stage II, base level 2", "Stage III, base level 3")
    said = {"court": "from the court, as the player sees it", "front": "head-on from the gate's side, 20 away",
            "side": "from the generator's side, 18 away", "far": "from the side wall's side, 18 away",
            "back": "from behind the stone, 12 away", "three": "three-quarter, from the front and the generator's side",
            "high": "from above, 40 degrees down, three-quarter",
            "sideturned": "from the generator's side, the crown at its second turn (I 90, II 45, III 30 degrees)",
            "backturned": "from behind the stone, the crown at its second turn"}
    (a1, t1), (a2, t2), (a3, t3) = (bm.crown_size(s) for s in (1, 2, 3))
    notes = [
        "The crown carries more. The stone, its reticle, the spark and the pad stay Stage I's at every stage. Stage I's "
        f"crown is remade in the family: a band of void stone {a1:.1f} across, four short crystals set through it and "
        f"eight marks of the void's light on its rim, and three tall crystals near the spark, their tips {t1:.2f} over "
        f"the crown's middle. At Stage II, {a2:.1f} across, six short crystals and twelve marks, and four tall, their "
        f"tips {t2:.2f} over it; at Stage III, {a3:.1f} across, eight short and sixteen marks, and six tall, their tips "
        f"{t3:.2f} over it. Short at the rim and tall near the spark, so its top line rises to the middle from every "
        "side while it turns: a crown, never weights at a bar's ends. Every crystal stands upright and unlit, joined "
        "to nothing. Each stage's crown replaces the one before's and turns as it does.",
        "In the base kit's colours, in the yard at base level 3 under the place's dusk, the yard's trainee on the pad, "
        "rendered in Blender; nothing is seen in Studio. Triangles, a stage whole before the drawn edge's hull: "
        + ", ".join(f"Stage {k} {tris[k]:,}" for k in keys) + "."]
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
    t.text(gap, 14, 20, "Grow your Anime, the Training machine's stages: the Weighted Crown (AR35)", "#EDE6D6", bold=0.2)
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
    rs.save(page.px, out / "training_stages.png")
    print("triangles:", tris)


def main():
    import blcommon as bl
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    if "sheet" in args:
        sheet(out)
    else:
        review(out, "fast" in args)


if __name__ == "__main__":
    main()
