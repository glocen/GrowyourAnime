"""AR33: the extraction bays' Stages II and III, the Horned Crown, as base kit pieces (docs/asset-requests.md, AR33).

A bay takes the stage of its own machine level: Stage I from level 1, II from 6, III from 15 (Config.Base, Stages).
The crescent grows. At Stage II its horns rise to 12, their tips still apart over the ring, a tine grows from each
shoulder up and out to 11, and a toothed ring of void stone stands round the ring. At Stage III the horns reach 14.5, a
second tine branches from each horn to 15.6, bone clamps hold the branches, and a second toothed ring stands outside the
first. The toothed rings turn, opposite ways, while a worker works there.

A bay grows on its outer side and up, never over its inner half or in front, so from the court, where the player meets
the bays (research's view for them, 2026-11-17), the growth stays behind the worker. The pad stays 10 square, and the
ring and its shard stay 8 up on the outer side, so BayHalo is right at every stage.

The pieces (base_kit.py takes PIECES), each in the bay's own frame, stood at the bay's place with the bay's turn:
  Bay2, Bay3     each stage's still bay, in place of Bay
  BayCog         the toothed ring round the ring, 16 teeth; it turns
  BayCogOuter    Stage III's second, outside the first, 22 teeth; it turns the other way
The swap's table is tables(): plan.json's machines.bayStages.

The content check's conditions (2026-11-17) hold: the ring and its shard stay as Stage I has them, pale, nothing orange
or red at them; the horns' tips stay apart over the ring; in black, no upright even crown; no tall tapering tower;
nothing written on a ring; the toothed rings' teeth short and square-ended, in matte void stone, unlit, with no spokes
and no brass, copper or gold near them; the bone clamps pale ivory.

The review, each stage in the yard at base level 3, from a player in the court turned to the left side's three bays and
head-on from the court, cut small and in black:
blender.exe -b --factory-startup --python-exit-code 1 --python tools/blender/base_bay.py -- <abs out_dir> [fast]
B, the Draw, the direction research didn't pick, is in git (e1c365d).
"""

import math
import sys
import textwrap
from pathlib import Path

from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_machines as bm  # noqa: E402
from base_mill import Mesh, at, prism, put  # noqa: E402
from lantern_row_kit import Piece  # noqa: E402

SIDE, TOP = bm.BAY
BACK = -(SIDE / 2 - 0.55)             # the crescent's plane, on the outer side
RING = bm.HALO[0]                     # the ring's middle, up
TO_X = Matrix.Rotation(math.pi / 2, 4, "Y")   # a part built about Z, turned so its Z lies along X, toward the worker

# Each stage's crescent: a horn from its foot to its tip, (across the pad, up), its half widths; the tines, each from
# where it leaves the horn to its tip; the bone clamps where they branch.
SHAPE = {
    2: dict(arm=[(3.7, TOP + 0.5), (4.9, 3.6), (4.6, 7.6), (3.5, 10.5), (2.1, 12.0)], widths=[0.8, 0.74, 0.6, 0.4, 0.05],
            tines=[([(4.55, 7.3), (4.85, 9.4), (4.97, 11.0)], [0.46, 0.32, 0.05])], clamps=[]),
    3: dict(arm=[(3.7, TOP + 0.5), (4.95, 4.0), (4.85, 8.5), (3.8, 12.2), (2.3, 14.5)], widths=[0.9, 0.82, 0.68, 0.46, 0.05],
            tines=[([(4.8, 8.3), (4.95, 10.6), (4.98, 12.4)], [0.5, 0.34, 0.05]),
                   ([(3.75, 12.3), (4.2, 14.0), (4.5, 15.6)], [0.42, 0.3, 0.05])],
            clamps=[(4.82, 8.4), (3.75, 12.3)]),
}
# The toothed rings: out to the teeth's root, teeth, the web's hole, and the way each turns.
COGS = {"BayCog": dict(r=2.75, teeth=16, hole=2.15, sign=1), "BayCogOuter": dict(r=3.55, teeth=22, hole=3.15, sign=-1)}
TOOTH = (0.3, 0.36)                   # a tooth: out past the root, and its width, square-ended
COG_THICK = 0.35


# --- the shapes -------------------------------------------------------------------------------------------------------

def ground(m):
    """The bay's deck, dais, well, inner corners, ring, shard and the current's outlet, as Stage I has them."""
    m.box((SIDE, SIDE, TOP), (0, 0, TOP / 2), "girder", ink=True)
    bm.rim(m, SIDE, SIDE, (0, 0, 0.2))                       # each light in its dark bed (AR40)
    m.lathe([(4.1, 0.16), (4.3, 0.0)], (0, 0, TOP), 12, "abyss")
    bm.dais_line(m, (0, 0, TOP), 3.55, 3.85, 12)
    bm.well(m, (0, 0, TOP), bm.DAIS_FLOOR)
    m.box((1.3, SIDE - 1.2, 0.6), (BACK, 0, TOP + 0.3), "abyss", ink=True)
    for sy in (-1, 1):
        bm.horn(m, [(4.35, sy * 4.35, TOP), (3.75, sy * 3.75, TOP + 1.7)], [0.42, 0.05], "abyss", flat=(sy, -1.0, 0.0))
        bm.shard(m, (3.6, sy * 3.6, TOP + 2.55), 0.24, 0.9, "void")
    bm.hoop(m, (BACK, 0, RING), bm.HALO[1], bm.HALO[2], 0.4, 12, "abyss")
    bm.shard(m, (BACK, 0, RING), 0.8, 3.0, "void", lean=0.55)
    m.box((0.9, 1.6, 1.0), (BACK + 0.3, 0, TOP + 0.5), "girder", ink=True)
    bm.lamp(m, (0.1, 1.0, 0.2), (BACK + 0.78, 0, TOP + 0.6), "power", 0, 1, pad=0.15)


def still(stage):
    """A stage's still bay: Stage I's ground, the grown crescent with a vein in each horn stopping over a stud short of
    its tip, the tines, and the bone clamps."""
    m = Mesh()
    ground(m)
    shape = SHAPE[stage]
    arm, widths, t = shape["arm"], shape["widths"], 0.35
    end = tuple(a + (b - a) * t for a, b in zip(arm[-2], arm[-1]))
    for sy in (-1, 1):
        pts = [(BACK, sy * y, z) for y, z in arm]
        bm.horn(m, pts, widths, "abyss", flat=(1.0, 0.0, 0.0), deep=0.75)
        bm.vein(m, pts[:-1] + [(BACK, sy * end[0], end[1])], widths[:-1] + [widths[-2] + (widths[-1] - widths[-2]) * t],
                (BACK, 0, 5.5), r=0.08)
        for line, radii in shape["tines"]:
            bm.horn(m, [(BACK, sy * y, z) for y, z in line], radii, "abyss", flat=(1.0, 0.0, 0.0), deep=0.75)
        for y, z in shape["clamps"]:
            m.box((0.9, 0.8, 0.7), (BACK, sy * y, z), "bone", ink=True)
    return m


def cog(name):
    """A toothed ring about its own axle, the piece's X: a web of void stone from its hole out to the teeth's root, and
    short, square-ended teeth as long as they're wide."""
    c = COGS[name]
    g = Mesh()
    bm.hoop(g, (0, 0, 0), c["hole"], c["r"] + 0.02, COG_THICK, max(c["teeth"], 12), "abyss", lying=True)
    out, wide = TOOTH
    for k in range(c["teeth"]):
        a = math.tau * (k + 0.5) / c["teeth"]
        o, s = Vector((math.cos(a), math.sin(a), 0.0)), Vector((-math.sin(a), math.cos(a), 0.0))
        rim = [o * c["r"] - s * wide / 2, o * (c["r"] + out) - s * wide / 2, o * (c["r"] + out) + s * wide / 2,
               o * c["r"] + s * wide / 2]
        prism(g, rim, COG_THICK, "abyss", o * (c["r"] + out / 2))
    m = Mesh()
    put(m, g, TO_X)
    return m


# --- the kit's pieces and the swap's table ------------------------------------------------------------------------------

def bay_stage(stage):
    def make():
        grown = ("its horns risen to 12, their tips apart over the ring, and a tine from each shoulder to 11" if stage == 2
                 else "its horns risen to 14.5, a tine from each shoulder to 12.4 and a second branching from each horn "
                      "to 15.6, bone clamps where they branch")
        return Piece(f"Bay{stage}", still(stage), solid="a box, 10 square, 0.4 high, and the crescent's two feet",
                     note=f"Stage {'II' if stage == 2 else 'III'}'s still bay, in place of Bay at the same place and "
                          f"turn: {grown}. The worker stands at the pad's middle; the ring's middle is {RING:g} up, as "
                          f"Stage I's, so BayHalo stands as it does. The toothed rings stand by machines.bayStages")
    return make


def bay_cog(name):
    def make():
        c = COGS[name]
        which = ("round the ring, from Stage II" if name == "BayCog" else "Stage III's second, outside the first")
        return Piece(name, cog(name),
                     note=f"a toothed ring of void stone {which}: {c['teeth']} square teeth, "
                          f"{2 * (c['r'] + TOOTH[0]):g} across, unlit. Its origin on its axle's middle; its axle along "
                          f"the piece's X (Roblox's X). It turns while a worker works there, CFrame.Angles(angle * sign, "
                          f"0, 0) with the sign the table gives, so the two turn opposite ways. Look only")
    return make


def stages():
    """The swap's table: each stage's pieces at the bay's place (across, toward the gate, up), and how each moves."""
    table = {}
    for stage in (1, 2, 3):
        rows = [dict(piece="Bay" if stage == 1 else f"Bay{stage}", at=[0.0, 0.0, 0.0], moves="still")]
        for name in (() if stage == 1 else ("BayCog",) if stage == 2 else ("BayCog", "BayCogOuter")):
            rows.append(dict(piece=name, at=[round(BACK, 3), 0.0, RING], moves="turns", sign=COGS[name]["sign"]))
        table[str(stage)] = dict(pieces=rows)
    return table


def tables():
    return dict(bayStages=dict(
        note="AR33: the extraction bays' three stages, the Horned Crown, the swap's table. A bay takes the stage of its "
             "own machine level (Config.Base, Stages: 1, 6, 15). Every place is in the bay's own frame, turned with "
             "it as Bay is (0 on the plot's left, 180 on its right): `across` toward the outer side's crescent is "
             "negative, `along` toward the gate, `up` from its floor. A stage's pieces replace the one before's. "
             "`moves`: still; turns, about the piece's own axle while a worker works there, CFrame.Angles(angle * "
             "sign, 0, 0). BayHalo and BaySleeping stand as they do at every stage.",
        stages=stages()))


PIECES = {"Bay2": bay_stage(2), "Bay3": bay_stage(3), "BayCog": bay_cog("BayCog"), "BayCogOuter": bay_cog("BayCogOuter")}


# --- the review: each stage in the yard, from the court -----------------------------------------------------------------

def stood(stage):
    """A stage whole, every piece at its table's place: for the review."""
    m = Mesh()
    made = {"Bay": bm.bay().mesh, "Bay2": still(2), "Bay3": still(3), "BayCog": cog("BayCog"),
            "BayCogOuter": cog("BayCogOuter")}
    for row in stages()[str(stage)]["pieces"]:
        put(m, made[row["piece"]], at(*row["at"]))
    return m


def toward(at_, target):
    """The game's camera behind a player at `at_` (across, in), turned to `target` (across, in): Roblox's start zoom and
    the replay's pitch, as base_plan's behind()."""
    import lantern_row_look as look
    pitch, focus = math.radians(20.0), Vector((at_[0], -at_[1], 3.0 + look.FOCUS))
    flat = Vector((target[0] - at_[0], -(target[1] - at_[1]), 0.0)).normalized()
    eye = focus - flat * math.cos(pitch) * look.ZOOM + Vector((0, 0, 1)) * math.sin(pitch) * look.ZOOM
    return tuple(eye), tuple(focus)


def review(out, fast):
    import numpy as np
    import bpy
    from bpy_extras.object_utils import world_to_camera_view
    import base_kit as base
    import base_plan as plan
    import blcommon as bl
    import lantern_row_look as look
    import rook_sheet as rs
    import ui_sheet as ui

    level = 3                                  # all six bays open
    made = plan.machines                       # the yard as it stands, its bays taken out (their halos stay)
    plan.machines = lambda lv=1: [row for row in made(lv) if row[0] != "Bay"]
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

    bx, bi = base.BAYS[0]
    views = {"row": toward((-4.0, 36.0), (bx - 8.0, bi + 8.0)),                  # a player in the court, turned to the Door's side's bays
             "court": ((bx + 19.5, -bi, 8.5), (bx, -bi, 7.0))}                   # head-on to bay 1
    w, h = look.SIZE
    shots, boxes, black, tris = {}, {}, {}, {}

    def silhouette(obj, path):
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
        px = rs.load(path)
        ink = np.ones_like(px)
        ink[..., :3] = 1.0 - px[..., 3:4]
        path.unlink()
        return ink

    for key, stage in (("I", 1), ("II", 2), ("III", 3)):
        mesh = stood(stage)
        tris[key] = mesh.whole().tris()
        data = mesh.whole().to_object(f"Bay{key}", yard.stock.mats["Kit"])
        objs = []
        for i, (x, inward) in enumerate(plan.BAY_LOTS[:base.BAYS_AT[level]]):
            obj = bpy.data.objects.new(f"Bay{key}{i}", data)
            obj.location, obj.rotation_euler = (x, -inward, 0.0), (0, 0, math.radians(0.0 if x < 0 else 180.0))
            scene.collection.objects.link(obj)
            objs.append(obj)
        bpy.context.view_layer.update()
        close = objs[0]                                   # level 1's bay on the left, the one the court view faces
        for name, (eye, target) in views.items():
            scene.camera = plan.camera(scene, f"Cam{key}{name}", eye, target)
            path = out / f"bay_{key}_{name}.png"
            shots[(key, name)] = look.finish(look.render_linear(scene, path.with_suffix(".exr")), d)
            path.with_suffix(".exr").unlink(missing_ok=True)
        pts = [world_to_camera_view(scene, scene.camera, close.matrix_world @ v.co) for v in close.data.vertices]
        boxes[key] = (min(p.x for p in pts) * w, min((1 - p.y) for p in pts) * h,
                      max(p.x for p in pts) * w, max((1 - p.y) for p in pts) * h)
        black[key] = silhouette(close, out / f"_black_{key}.png")
        for obj in objs:
            bpy.data.objects.remove(obj)
        bpy.data.meshes.remove(data)

    keys = ("I", "II", "III")
    b = [boxes[k] for k in keys]
    union = (min(v[0] for v in b) - 6, min(v[1] for v in b) - 6, max(v[2] for v in b) + 6, max(v[3] for v in b) + 6)
    x0, y0, x1, y1 = (int(v) for v in union)
    x0, y0 = max(x0, 0), max(y0, 0)

    def cut(px, tall):
        piece = px[y0:y1, x0:x1]
        return rs.shrink(piece, tall / piece.shape[0])

    titles = ("Stage I, machine levels 1 to 5, as it stands", "Stage II, levels 6 to 14", "Stage III, levels 15 and up")
    notes = [
        "The crescent grows. At Stage II its horns rise to 12, their tips still apart over the ring, a tine grows from "
        "each shoulder up and out to 11, and a toothed ring of void stone (16 square teeth, unlit) stands round the "
        "ring. At Stage III the horns reach 14.5, a second tine branches from each horn to 15.6, bone clamps hold the "
        "branches, and a second toothed ring (22 teeth) stands outside the first. The toothed rings are their own "
        "pieces and turn, opposite ways, while a worker works there.",
        "The pad stays 10 square, and the ring and its shard stay 8 up on the outer side, so BayHalo stands as it does. "
        "All six bays at base level 3, at the same stage, a player's size on each. In the base kit's colours, in the "
        "yard as it stands under the place's dusk, rendered in Blender; nothing is seen in Studio. Triangles, a stage's "
        "pieces together, before the drawn edge's hull: " + ", ".join(f"Stage {k} {tris[k]:,}" for k in keys) + "."]
    lines = [ln for n in notes for ln in textwrap.wrap(n, 230)]
    gap = 16
    cw, ch = round(w * 2 / 3), round(h * 2 / 3)           # 640 by 360: about a phone's screen in points
    full = [shots[(k, "court")][y0:y1, x0:x1] for k in keys]
    full_h = max(px.shape[0] for px in full)
    small_h = 64 + 128 + 2 * gap + 64
    width = max(3 * cw + 4 * gap, sum(px.shape[1] for px in full) + 4 * gap)
    height = 48 + 22 + (ch + 34) + 34 + full_h + 34 + small_h + len(lines) * 19 + 24
    ui.K = 1
    page = ui.Sheet(width, height, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 14, 20, "Grow your Anime, the bays' stages: the Horned Crown (AR33)", "#EDE6D6", bold=0.2)
    y = 48
    t.text(gap, y, 14, "A player in the court turned to the left side's three bays, at a phone's 640 by 360", "#B4AC9C")
    y += 22
    for i, k in enumerate(keys):
        x = gap + i * (cw + gap)
        t.text(x, y, 14, titles[i], "#EDE6D6")
        rs.paste(page.px, rs.shrink(shots[(k, "row")], 2 / 3), x, y + 22)
    y += ch + 34
    t.text(gap, y, 14, "Level 1's bay on the left, head-on from the court, at its own size on a 960 by 540", "#B4AC9C")
    x = gap
    for px in full:
        rs.paste(page.px, px, x, y + 22)
        x += px.shape[1] + gap
    y += full_h + 34 + 8
    t.text(gap, y, 14, "The same, cut at one scale for the three: 64 and 128 px tall over the dark, and in black", "#B4AC9C")
    x = gap
    for i, k in enumerate(keys):
        left = x
        for px in (cut(shots[(k, "court")], 64), cut(black[k], 64)):
            rs.paste(page.px, px, x, y + 26)
            x += px.shape[1] + 8
        x = left
        for px in (cut(shots[(k, "court")], 128), cut(black[k], 128)):
            rs.paste(page.px, px, x, y + 26 + 64 + gap)
            x += px.shape[1] + 8
        t.text(left, y + 26 + 64 + 128 + 2 * gap, 13, titles[i].split(",")[0], "#EDE6D6")
        x += 2 * gap
    y += small_h
    for i, ln in enumerate(lines):
        t.text(gap, y + i * 19, 14, ln, "#B4AC9C")
    for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
        rs.paste(page.px, layer, 0, 0)
    rs.save(page.px, out / "bay_stages.png")
    for (key, name), px in shots.items():
        rs.save(px, out / f"bay_{key}_{name}.png")
    print("triangles:", tris)


def main():
    import blcommon as bl
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    review(out, "fast" in args)


if __name__ == "__main__":
    main()
