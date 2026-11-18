"""AR34: the battery's Stages II and III, the Rising Stack, as base kit pieces (docs/asset-requests.md, AR34).

The battery takes the base's level: Stage I at level 1, II at 2, III at 3, launch's cap. Its cells, 2, 4 and 8 by the
base's level (Config.Base, Levels.Cells), climb: at Stage II they stand in two tiers of two, at Stage III in four, held
between two uprights of void stone, each in a clamp of bone from its side, no bar across a tier, and the fill lights tier
by tier from the bottom, a gauge. At Stage III each upright rises into two straight points, front and back, and a bead
of the void's light rests low between them on the one top bar, with open sky above it.

Research's class for these pieces (AR34, "Research's pick"): the stack never reads as a building or shelving. The cells
are things held in a frame, gripped from the side, with the sky under and over each tier, never lit panes in a wall:
no bar crosses a tier, so nothing reads as a floor. The uprights are void stone's tapering shafts,
not columns; the materials are void stone and bone, as in the bays.

Stage I is the deck alone (base_machines.battery_deck, BatteryRack): AR19's note made, the copper bar a groove of void
stone with the current's line in it, the posts void stone, squared, their insulators gone.

The pieces (base_kit.py takes PIECES), in the battery's own frame, stood at its place, turn 0:
  BatteryRack2, BatteryRack3   each stage's still battery, in place of BatteryRack
BatteryCell is unchanged; the table gives each stage's seats, in the order the cells fill.
The swap's table is tables(): plan.json's machines.batteryStages.

The content check's conditions (2026-11-17) hold: the ties end at the uprights' inner faces, no T or plus; the points
straight and chiselled, apart, leaning a little outward, never hooking in; the bead seated low on the top bar between
the points' roots, never floating between horns or capping a column; no copper, brass or gold; nothing written; no
red; the reads hold from every heading.

The review, each stage in the yard at base level 3, from the court and on the way to the back bay, head-on, from a
side, from behind and three-quarter, cut small and in black. Two runs, so the sheet's page never shares memory with the
yard's scene: the shots, then the sheet from them.
blender.exe -b --factory-startup --python-exit-code 1 --python tools/blender/base_battery.py -- <abs out_dir> [fast]
blender.exe -b --factory-startup --python-exit-code 1 --python tools/blender/base_battery.py -- <abs out_dir> sheet
B, the Ridge, the direction research didn't pick, is in git (d9c61e7).
"""

import json
import math
import sys
import textwrap
from pathlib import Path

from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_machines as bm  # noqa: E402
from base_mill import Mesh, at, put  # noqa: E402
from lantern_row_kit import Piece  # noqa: E402

SEAT = bm.SEAT
PITCH = 2.8             # a tier's rise: a cell is 2.16 high with its terminal; 1.1 of sky from its cap to the next cell
POST = 1.6              # the uprights' middles, across: hugging the pair's caps, so no slit runs up beside them
HALF = 0.28             # an upright's half width across, at its middle; a diamond, its corners across and along
STACK_Y = -0.95         # the stack stands on the deck's back half, its front toward the gate
CELL_X = 0.66           # a cell's middle, across: a tier's pair stands close, caps 0.02 apart, one unit
GRIP = CELL_X + 0.45    # a clamp's inner end, across: over the cell's outer edge, clear of its window
# The sky shows between the tiers only. A gap between the pair as well would cross the tiers' gaps, and the stack's
# silhouette would draw a cross (the content check's "no T or plus", 2026-11-17).
TIERS = {1: 1, 2: 2, 3: 4}
EMPTY = 0.2             # an empty cell's glow, of a lit one's: LightingConfig.Glow.Empty


def top(stage):
    """Where the uprights end: over the top tier's terminal, with the top bar's room."""
    return SEAT + (TIERS[stage] - 1) * PITCH + 2.4


def seats(stage):
    """A stage's seats in the order they fill: the bottom tier first, left to right. A cell's origin is its seat."""
    return [(sx * CELL_X, STACK_Y, round(SEAT + k * PITCH, 3)) for k in range(TIERS[stage]) for sx in (-1, 1)]


def frame(m, stage):
    """The uprights, a clamp of bone holding each cell, the points, and Stage III's top bar and bead. No bar crosses a
    tier: a cell is held from its side, with the sky under and over it, never stood on a floor."""
    head = top(stage)
    if stage == 3:                                         # the bead's rest, ending at the uprights' inner faces
        m.box((2 * (POST - HALF), 0.5, 0.14), (0, STACK_Y, head - 0.07), "bone", ink=True)
    for sx in (-1, 1):
        bm.horn(m, [(sx * POST, STACK_Y, SEAT - 0.05), (sx * POST, STACK_Y, (SEAT + head) / 2),
                    (sx * POST, STACK_Y, head)], [HALF + 0.05, HALF, HALF - 0.03], "abyss", flat=(0.0, 1.0, 0.0),
                deep=1.6)
        for k in range(TIERS[stage]):                      # a clamp from the upright over the cell's outer edge
            m.box((POST - GRIP, 1.64, 0.32), (sx * (POST + GRIP) / 2, STACK_Y, SEAT + k * PITCH + 0.8), "bone",
                  ink=True)
        if stage == 3:
            m.box((2 * HALF + 0.16, 1.15, 0.28), (sx * POST, STACK_Y, head - 0.07), "bone", ink=True)
        for sy in (-1, 1):                                 # a point at the front and one at the back
            rise = (1.0, 0.0) if stage == 2 else (1.0, 1.9)
            pts = [(sx * POST, STACK_Y + sy * 0.4, head), (sx * (POST + 0.1), STACK_Y + sy * 0.5, head + rise[0])]
            radii = [0.2, 0.03]
            if stage == 3:                                 # straight, leaning a little out: never a hook
                pts = [pts[0], (sx * (POST + 0.12), STACK_Y + sy * 0.5, head + rise[0]),
                       (sx * (POST + 0.25), STACK_Y + sy * 0.6, head + rise[1])]
                radii = [0.22, 0.16, 0.03]
            bm.horn(m, pts, radii, "abyss", flat=(0.0, 1.0, 0.0), deep=1.5)
    if stage == 3:
        bm.shard(m, (0.0, STACK_Y, head + 0.52), 0.36, 1.1, "void")  # its foot set in the top bar, the sky open above
        m.box((0.5, 0.46, 0.04), (0.0, STACK_Y, head + 0.02), "well")   # the bead's dark socket on its rest (AR40)


def still(stage):
    m = Mesh()
    bm.battery_deck(m)
    frame(m, stage)
    return m


# --- the kit's pieces and the swap's table ------------------------------------------------------------------------------

def rack(stage):
    def make():
        head = top(stage)
        tip = head + (1.0 if stage == 2 else 1.9)
        return Piece(f"BatteryRack{stage}", still(stage),
                     solid=f"a box, 6 by 4, 0.6 high, the deck; and the stack's round its cells, "
                           f"{2 * (POST + HALF):g} across by 1.6 deep by {head:g} high, its middle {-STACK_Y:g} back "
                           f"from the deck's",
                     note=f"Stage {'II' if stage == 2 else 'III'}'s still battery, base level {stage}, in place of "
                          f"BatteryRack at the same place, turn 0: the deck, and two uprights of void stone holding "
                          f"{TIERS[stage]} tiers of two cells in clamps of bone, rising to points at {tip:.2f}"
                          + (", a bead of the void's light resting between them on the top bar" if stage == 3 else "")
                          + ". Its cells stand on the seats machines.batteryStages gives, in the order they fill")
    return make


def stages():
    """The swap's table: each stage's still piece, and its cells' seats in the order they fill, in the battery's own
    frame (across, toward the gate, up)."""
    table = {}
    for stage in (1, 2, 3):
        table[str(stage)] = dict(
            pieces=[dict(piece="BatteryRack" if stage == 1 else f"BatteryRack{stage}", at=[0.0, 0.0, 0.0], moves="still")],
            seats=[[x, y, z] for x, y, z in seats(stage)])
    return table


def tables():
    return dict(batteryStages=dict(
        note="AR34: the battery's three stages, the Rising Stack, the swap's table. The battery takes the stage of the "
             "base's level (Stage I at 1, II at 2, III at 3), and shows that level's cells (Config.Base, Levels.Cells: "
             "2, 4, 8), one on each of its stage's seats. Every place is in the battery's own frame, turn 0: `across`, "
             "`along` toward the gate, `up` from its floor. A stage's piece replaces the one before's. `seats` are in "
             "the order the cells fill: the bottom tier first, left to right, so the charge climbs. BatteryCell is "
             "unchanged; each cell's glow is its share of the charge, as today. This supersedes machines.battery's "
             "seats once installed.",
        stages=stages()))


PIECES = {"BatteryRack2": rack(2), "BatteryRack3": rack(3)}


# --- the review: each stage in the yard ---------------------------------------------------------------------------------

LIT = {1: 1, 2: 3, 3: 5}               # the review's charge: cells lit, of the 2, 4 and 8 a stage holds
FULL_VIEWS = ("front", "side", "three")                     # at their own size
CUT_VIEWS = ("front", "side", "far", "back", "three")       # cut small and in black


def toward(at_, target):
    """The game's camera behind a player at `at_` (across, in), turned to `target`: the start zoom and pitch."""
    import lantern_row_look as look
    pitch, focus = math.radians(20.0), Vector((at_[0], -at_[1], 3.0 + look.FOCUS))
    flat = Vector((target[0] - at_[0], -(target[1] - at_[1]), 0.0)).normalized()
    eye = focus - flat * math.cos(pitch) * look.ZOOM + Vector((0, 0, 1)) * math.sin(pitch) * look.ZOOM
    return tuple(eye), tuple(focus)


def review(out, fast):
    """The shots, each saved with its shape's silhouette and its box on the picture (battery_review.json)."""
    import bpy
    from bpy_extras.object_utils import world_to_camera_view
    import base_kit as base
    import base_plan as plan
    import blcommon as bl
    import lantern_row_look as look
    import rook_sheet as rs
    import ui_sheet as ui

    level, spot = 3, base.BATTERY
    made = plan.machines
    plan.machines = lambda lv=1: [row for row in made(lv) if row[0] not in ("BatteryRack", "BatteryCell")]
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
    yard.person((spot[0] + 5.2, -(spot[1] - 1.0)))                       # a player beside it, for its size
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
    dim = kit_mat.copy()                                   # an empty cell: the glow at the game's empty share
    for node in dim.node_tree.nodes:
        if node.type == "MATH" and node.operation == "MULTIPLY" and node.inputs[0].is_linked \
                and node.inputs[0].links[0].from_node.type == "TEX_IMAGE":
            node.inputs[1].default_value *= EMPTY

    x, inward = spot
    mid = (x, -inward, 6.0)
    views = {"court": toward((16.0, 36.0), spot),                       # a player at the court's back, turned to it
             "way": toward((43.0, 56.0), spot),                         # on the way to the right side's back bay
             "front": ((x, -(inward - 18.0), 7.5), mid),
             "side": ((x - 18.0, -inward, 7.5), mid),
             "far": ((x + 18.0, -inward, 7.5), mid),
             "back": ((x, -(inward + 12.0), 6.5), mid),
             "three": ((x - 13.0, -(inward - 13.0), 7.5), mid)}
    w, h = look.SIZE
    boxes, tris = {}, {}

    def silhouette(objs, path):
        """The stage alone in the workbench, its shape as the picture's alpha (the sheet draws it black)."""
        hidden = [o for o in scene.objects if o not in objs and o.type == "MESH" and not o.hide_render]
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
        body, empty = Mesh(), Mesh()
        put(body, bm.battery_rack().mesh if stage == 1 else still(stage), at(0, 0, 0))
        cell = bm.battery_cell().mesh
        for i, (cx, cy, cz) in enumerate(seats(stage)):
            put(body if i < LIT[stage] else empty, cell, at(cx, cy, cz))
        tris[key] = body.whole().tris() + empty.whole().tris() - len(seats(stage)) * cell.whole().tris()
        objs = []
        for name, mesh, mat in (("Body", body, kit_mat), ("Empty", empty, dim)):
            data = mesh.whole().to_object(f"Battery{key}{name}", mat)
            obj = bpy.data.objects.new(f"Battery{key}{name}", data)
            obj.location = (x, -inward, 0.0)
            scene.collection.objects.link(obj)
            objs.append(obj)
        bpy.context.view_layer.update()
        for name, (eye, target) in views.items():
            scene.camera = plan.camera(scene, f"Cam{key}{name}", eye, target)
            path = out / f"battery_{key}_{name}.png"
            rs.save(look.finish(look.render_linear(scene, path.with_suffix(".exr")), d), path)
            path.with_suffix(".exr").unlink(missing_ok=True)
            if name in CUT_VIEWS:
                pts = [world_to_camera_view(scene, scene.camera, o.matrix_world @ v.co) for o in objs
                       for v in o.data.vertices]
                boxes[f"{key} {name}"] = (min(p.x for p in pts) * w, min((1 - p.y) for p in pts) * h,
                                          max(p.x for p in pts) * w, max((1 - p.y) for p in pts) * h)
                silhouette(objs, out / f"black_{key}_{name}.png")
        for obj in objs:
            data = obj.data
            bpy.data.objects.remove(obj)
            bpy.data.meshes.remove(data)
    (out / "battery_review.json").write_text(json.dumps(dict(boxes=boxes, tris=tris)), encoding="utf-8")


def sheet(out):
    """The review sheet from the shots on disk, in a Blender of its own: the yard's scene is gone, so the page and its
    text fit in memory beside Studio."""
    import numpy as np
    import rook_sheet as rs
    import ui_sheet as ui
    import lantern_row_look as look

    saved = json.loads((out / "battery_review.json").read_text(encoding="utf-8"))
    boxes, tris = {tuple(k.split(" ")): v for k, v in saved["boxes"].items()}, saved["tris"]
    cut_views = CUT_VIEWS
    w, h = look.SIZE

    def shot(key, name):
        return rs.load(out / f"battery_{key}_{name}.png")

    def blackened(key, name):
        px = rs.load(out / f"black_{key}_{name}.png")
        ink = np.ones_like(px)
        ink[..., :3] = 1.0 - px[..., 3:4]
        return ink

    keys = ("I", "II", "III")

    def union(name):
        b = [boxes[(k, name)] for k in keys]
        return tuple(int(v) for v in (max(min(q[0] for q in b) - 8, 0), max(min(q[1] for q in b) - 8, 0),
                                      max(q[2] for q in b) + 8, max(q[3] for q in b) + 8))

    def crop(px, box):
        return px[box[1]:box[3], box[0]:box[2]]

    unions = {name: union(name) for name in cut_views}
    fulls = {name: [crop(shot(k, name), unions[name]) for k in keys] for name in cut_views}
    full_views = FULL_VIEWS
    titles = ("Stage I, base level 1", "Stage II, base level 2", "Stage III, base level 3")
    said = {"front": "head-on from the court's side, 18 away", "side": "from the generator's side, 18 away",
            "far": "from the side wall's side, 18 away", "back": "from behind, 12 away", "three": "three-quarter, from the front and the generator's side"}
    notes = [
        "The cells climb. Stage I is the deck alone: AR19's note made, the copper bar a groove of void stone with the "
        "current's line in it, the posts void stone, its two cells at the stack's foot. At Stage II two uprights of "
        "void stone, tapering shafts, hold the four cells in two tiers of two, each cell in a clamp of bone from its "
        "side, no bar across a tier, a tier's pair close as one, the sky under and over each tier; they rise to short "
        "points, front and back. At Stage III they hold four tiers, and rise into straight points leaning a little outward, a "
        "bead of the void's light resting low between them on the one top bar, open sky above it. The fill lights "
        "tier by tier from the bottom.",
        "The footprint stays inside 6.6 by 4.6. The charge shown: Stage I 1 cell lit of 2, Stage II 3 of 4, Stage III 5 "
        "of 8; an empty cell glows at the game's empty share, 0.2 of a lit one's. In the base kit's colours, in the "
        "yard at base level 3 under the place's dusk, a player beside it, rendered in Blender; nothing is seen in "
        "Studio. Triangles, each stage's still piece before the drawn edge's hull: "
        + ", ".join(f"Stage {k} {tris[k]:,}" for k in keys) + "; BatteryCell's are its own."]
    lines = [ln for n in notes for ln in textwrap.wrap(n, 230)]
    gap = 16
    cw, ch = round(w * 2 / 3), round(h * 2 / 3)
    small = 26 + 64 + gap + 128 + gap + 20
    widths = [sum(px.shape[1] for px in fulls[n]) + 4 * gap for n in full_views]
    cuts = [3 * (2 * round(128 * px.shape[1] / px.shape[0]) + 8 + 2 * gap) + 2 * gap
            for n in cut_views for px in fulls[n][:1]]
    width = max(3 * cw + 4 * gap, *widths, *cuts, 1300)
    height = 48 + 2 * (ch + 34) + sum(max(px.shape[0] for px in fulls[n]) + 42 for n in full_views) \
        + len(cut_views) * small + 34 + len(lines) * 19 + 24
    ui.K = 1                                               # a point a pixel: the sheet is laid out in pixels
    page = ui.Sheet(width, height, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 14, 20, "Grow your Anime, the battery's stages: the Rising Stack (AR34)", "#EDE6D6", bold=0.2)
    y = 48
    for name, caption in (("court", "a player at the court's back turned to it, at a phone's 640 by 360"),
                          ("way", "a player between the right side's bays, on the way to the back one, turned to it")):
        for i, k in enumerate(keys):
            x0 = gap + i * (cw + gap)
            t.text(x0, y, 14, f"{titles[i]}: {caption}" if i == 0 else titles[i], "#B4AC9C")
            rs.paste(page.px, rs.shrink(shot(k, name), 2 / 3), x0, y + 22)
        y += ch + 34
    for name in full_views:
        t.text(gap, y, 14, f"{said[name]}, at its own size on a 960 by 540", "#B4AC9C")
        x0 = gap
        for px in fulls[name]:
            rs.paste(page.px, px, x0, y + 22)
            x0 += px.shape[1] + gap
        y += max(px.shape[0] for px in fulls[name]) + 42
    for name in cut_views:
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
    rs.save(page.px, out / "battery_stages.png")
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
