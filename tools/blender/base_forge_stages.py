"""AR36: the Forge's and the Stone Condenser's Stages II and III as base kit pieces (docs/asset-requests.md, AR36;
research's picks: the Forge's A, the Gear Train, and the Condenser's B, the Climbing Comb). Stage I is AR28's Press
and Comb (base_forge.py).

The Forge takes the base's level: Stage I at 1, II at 2, III at 3. Its head widens into a lintel 7.6 across on the
horns' shoulders, carrying four gears in a row, each meshing the next (Forge2). At III the lintel's ends step up to
carry two more, each over an outer gear and meshing only it, and each horn takes three bone clamps (Forge3). The
seat, the plate, the ram and its poses stay Stage I's; the gears are ForgeGear at every stage, void stone with a vein
of the void's light (research's class on the pick), so Stage I's two are re-exported in the same stone.

The Stone Condenser takes its own level: Stage I at 1 to 5, II at 6 to 14, III at 15 and up. Cups climb its horns'
outer sides, each on a six-sided plate facing the gate: three a side at II (Condenser2), five at III (Condenser3).
Each chain stops a cup below the block's, so the top stays open and the horns read as horns (research's class). The
comb, the core and the horns stay Stage I's, and the climbing cups take stones and jewels as the comb's do, in the
fill's order by height, so the lit height is still the fill.

Not run by itself for the kit: base_kit.py takes PIECES into its own, base_plan.py the tables. Run, it renders the
review in colour: each stage in the yard at base level 3, in two passes so the page fits in memory beside Studio:
blender.exe -b --factory-startup --python-exit-code 1 --python tools/blender/base_forge_stages.py -- <abs out_dir> forge|condenser [fast]
blender.exe -b --factory-startup --python-exit-code 1 --python tools/blender/base_forge_stages.py -- <abs out_dir> forge|condenser sheet
"""

import json
import math
import sys
import textwrap
from pathlib import Path

from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_forge as bf  # noqa: E402
from base_mill import FACING, Mesh, at, prism, put  # noqa: E402
import lantern_row_kit as kit  # noqa: E402

Piece = kit.Piece
LINTEL = 7.6              # the lintel across, on the horns' shoulders
CHEEK = (0.9, 2.2, 3.35)  # the lintel's cheeks down onto the horns: across, deep, their middle's reach
STEP = (2.1, 1.9, 2.75)   # Stage III's raised ends: across, high, their middle's reach
ARCH = [(3.2, 0.0, 0.5), (4.7, 0.0, 4.4), (4.1, 0.0, 8.8), (1.7, 0.0, 11.3)]   # the Forge's right horn (base_forge.forge)
ARCH_R = [0.8, 0.72, 0.58, 0.42]
CLAMPS = ((0, 0.45), (1, 0.2), (1, 0.7))   # a horn's bone clamps at Stage III: the stretch, and how far along it
CLIMB = {1: 0, 2: 3, 3: 5}                 # climbing cups a side, by stage
CLIMB_AT = (1.6, 1.06, 0.55)               # the lowest's height, the step between them, their gap off the horn's edge
PLATE = (0.66, 0.6)                        # a climbing cup's plate: its corner radius, its depth
FROM_LEVEL = {1: 1, 2: 6, 3: 15}           # the Condenser's own level each stage starts at (research, AR36)
ROMAN = {1: "I", 2: "II", 3: "III"}


# --- the Forge ---------------------------------------------------------------------------------------------------------

def gears(stage):
    """The stage's gears on the head's face: across, up, which way each turns as the ram lifts (+1 anticlockwise seen
    from the front, as Stage I's left one) and whether it is turned half a tooth, so each meshes its neighbours."""
    x, _, z, _ = bf.GEAR
    if stage == 1:
        return [(-x, z, 1, False), (x, z, -1, True)]
    p = 2 * x
    row = [(-1.5 * p, z, -1, True), (-0.5 * p, z, 1, False), (0.5 * p, z, -1, True), (1.5 * p, z, 1, False)]
    if stage == 3:
        row += [(-1.5 * p, z + p, 1, False), (1.5 * p, z + p, -1, True)]   # each over an outer one, meshing it alone
    return row


def gear_place(x, z, spin, half, angle=0.0):
    """A gear's place at (x, z) on the head's face, turned `angle` degrees of the ram's travel its own way."""
    return at(x, bf.GEAR[1], z) @ Matrix.Rotation(math.radians(spin * angle + (180.0 / bf.GEAR[3] if half else 0.0)), 4, "Y")


def clamps(m, points, radii):
    """A horn's bone clamps, each square to its stretch at the CLAMPS places."""
    across = Vector((0.0, 1.0, 0.0))
    for k, t in CLAMPS:
        a, b = Vector(points[k]), Vector(points[k + 1])
        along = (b - a).normalized()
        side = across.cross(along).normalized()
        r = radii[k] + (radii[k + 1] - radii[k]) * t
        m.box((2 * r + 0.26, 2 * r * 0.9 + 0.26, 0.32), a.lerp(b, t), "bone", ink=True,
              rot=Matrix((side, across, along)).transposed())


def frame(stage):
    """Forge2 or Forge3, all of it that stands still: Stage I's Press without its head, the lintel in its place on the
    horns' shoulders with its cheeks and its line of light; at III the raised ends and the horns' clamps."""
    m = bf.forge(head=False)
    low, top = bf.HEAD
    m.box((LINTEL, 2.4, top - low), (0, 0, (low + top) / 2), "abyss", ink=True)
    bf.field(m, 0.0, bf.GEAR[2], LINTEL - 0.6)                              # the void's light behind its gears
    w, deep, reach = CHEEK
    for sx in (-1, 1):
        m.box((w, deep, low - 9.0), (sx * reach, 0, (low + 9.0) / 2), "abyss", ink=True)
    if stage == 3:
        w, high, reach = STEP
        for sx in (-1, 1):
            m.box((w, 2.4, high), (sx * reach, 0, top + high / 2), "abyss", ink=True)
            bf.field(m, sx * reach, bf.GEAR[2] + 2 * bf.GEAR[0], w - 0.4)  # and behind the gear it carries
            clamps(m, [(sx * x, y, z) for x, y, z in ARCH], ARCH_R)
    return m


# --- the Stone Condenser -----------------------------------------------------------------------------------------------

def climbing(stage):
    """The climbing cups' places up the horns' outer sides, in the Condenser's frame: across and up, both sides."""
    pts, out = bf.horn(bf.panel_radius(), bf.PANEL[0]), []
    low, step, gap = CLIMB_AT
    for k in range(CLIMB[stage]):
        z = low + step * k
        seg = 0 if z <= pts[1][2] else 1
        (x0, _, z0), (x1, _, z1) = pts[seg], pts[seg + 1]
        t = (z - z0) / (z1 - z0)
        w = bf.HORN[seg] + (bf.HORN[seg + 1] - bf.HORN[seg]) * t
        x = round(x0 + (x1 - x0) * t + w + gap, 3)
        out += [(x, round(z, 3)), (-x, round(z, 3))]
    return out


def comb_cups(stage):
    """Every cup at a stage in the order they fill: by height from the bottom up, then from the middle out, the right
    one first, so a climbing cup fills with the comb's row at its height."""
    return sorted(bf.cups() + climbing(stage), key=lambda p: (round(p[1], 2), abs(p[0]), -p[0]))


def climber(stage):
    """Condenser2 or Condenser3, all of it that stands still: Stage I's Comb and its climbing cups, each on its plate."""
    m = bf.condenser()
    r, deep = PLATE
    for x, z in climbing(stage):
        plate = Mesh()
        prism(plate, [Vector((r * math.cos(math.radians(90 + 60 * k)), r * math.sin(math.radians(90 + 60 * k)), 0.0))
                      for k in range(6)], deep, "abyss", Vector((0, 0, 0)))
        put(m, plate, at(x, bf.FACE - deep / 2, z) @ FACING)
        bf.cup(m, x, z)
    return m


# --- the kit's pieces and the tables ------------------------------------------------------------------------------------

def forge_piece(stage):
    def make():
        n = len(gears(stage))
        tall = bf.HEAD[1] + (STEP[1] if stage == 3 else 0.0)
        return Piece(f"Forge{stage}", frame(stage),
                     solid=f"the deck, {bf.DECK:g} square and 0.5 high; the seat, 3.4 by 2.8 and {bf.PLATE:g} high; "
                           f"the horns' two feet",
                     note=f"Stage {ROMAN[stage]} of the Forge, base level {stage}, in place of Forge: on a sleeping "
                          f"place, its front toward the Strip, {tall:g} high at its head. The lintel carries {n} "
                          f"ForgeGear; the ram is ForgeRam, as at Stage I: plan.json, machines.forgeStages")
    return make


def condenser_piece(stage):
    def make():
        return Piece(f"Condenser{stage}", climber(stage),
                     solid=f"the deck, {bf.DECK:g} square and 0.5 high, and the panel as a box "
                           f"{2 * bf.panel_radius():.1f} by 1 by {math.sqrt(3) * bf.panel_radius():.1f}",
                     note=f"Stage {ROMAN[stage]} of the Stone Condenser, from its level {FROM_LEVEL[stage]}, in place "
                          f"of Condenser: Stage I's comb and {CLIMB[stage]} cups up each horn, "
                          f"{len(comb_cups(stage))} in all, dark when empty. A cup's stone or jewel is CondenserStone "
                          f"or CondenserJewel stood in it, the core CondenserCore: plan.json, machines.condenserStages")
    return make


def stages(machine):
    if machine == "forge":
        return {str(s): dict(frame="Forge" if s == 1 else f"Forge{s}",
                             gears=[dict(across=round(x, 3) + 0.0, along=bf.GEAR[1], up=round(z, 3), spin=spin,
                                         turnedHalfTooth=half) for x, z, spin, half in gears(s)]) for s in (1, 2, 3)}
    return {str(s): dict(fromLevel=FROM_LEVEL[s], frame="Condenser" if s == 1 else f"Condenser{s}",
                         cups=[dict(across=x, along=bf.FACE, up=z) for x, z in comb_cups(s)]) for s in (1, 2, 3)}


def tables():
    return dict(
        forgeStages=dict(
            note="AR36: the Forge's three stages, the Gear Train. It has no level of its own, so it takes the stage "
                 "of the base's level (Stage I at 1, II at 2, III at 3). Every place is in the Forge's own frame, as "
                 "machines.forge's. A stage's `frame` stands in place of the one before's; the ram, its poses and "
                 "the plate are machines.forge's at every stage. A ForgeGear stands at each of `gears`, turned half "
                 "a tooth about its axle when `turnedHalfTooth` (machines.forge.halfTooth), and turns with the ram "
                 "at machines.forge.degreesPerStud: `spin` 1 anticlockwise seen from the front as the ram lifts, as "
                 "Stage I's left gear, -1 the other way, so every gear turns against the ones it meshes.",
            stages=stages("forge")),
        condenserStages=dict(
            note="AR36: the Stone Condenser's three stages, the Climbing Comb. It takes its own level: a stage from "
                 "`fromLevel` (I at 1 to 5, II at 6 to 14, III at 15 and up). Every place is in the Condenser's own "
                 "frame, as machines.condenser's. A stage's `frame` stands in place of the one before's; the core is "
                 "machines.condenser's at every stage. `cups` is the stage's tray in its filling order, Stage I's "
                 "comb and the cups climbing the horns together by height: a stone or a jewel to a cup, as at Stage "
                 "I, so the lit height is the fill.",
            stages=stages("condenser")))


PIECES = {"Forge2": forge_piece(2), "Forge3": forge_piece(3), "Condenser2": condenser_piece(2),
          "Condenser3": condenser_piece(3)}


def whole(machine, stage, pose="rest", fill=0.5, jewels=()):
    """A stage whole from its table, for the review: the Forge with its ram in `pose` and its gears where the pose
    turns them; the Condenser with its core and a stone in the first `fill` of its cups, a jewel in those in `jewels`."""
    row = stages(machine)[str(stage)]
    if machine == "forge":
        m = bf.forge() if stage == 1 else frame(stage)
        low = bf.POSES[pose]
        put(m, bf.forge_ram(), at(0, 0, low))
        for g in row["gears"]:
            put(m, bf.forge_gear(), gear_place(g["across"], g["up"], g["spin"], g["turnedHalfTooth"],
                                                (low - bf.POSES["rest"]) * bf.TURN))
        return m, 0
    m = bf.condenser() if stage == 1 else climber(stage)
    put(m, bf.condenser_core(), at(*bf.CORE))
    places = row["cups"]
    for k, c in enumerate(places[:round(len(places) * fill)]):
        put(m, bf.condenser_jewel() if k in jewels else bf.condenser_stone(), at(c["across"], c["along"], c["up"]))
    return m, len(places)


# --- the review: each stage in the yard, in colour ----------------------------------------------------------------------

KEYS = {"forge": (("1", 1, dict(pose="rest")), ("2", 2, dict(pose="rest")), ("3", 3, dict(pose="rest")),
                  ("3c", 3, dict(pose="contact"))),
        "condenser": (("1", 1, dict(fill=0.5)), ("2", 2, dict(fill=0.5)), ("3", 3, dict(fill=0.5)),
                      ("3f", 3, dict(fill=1.0, jewels=(4, 19, 33))))}
TITLES = {"forge": ("Stage I, base level 1", "Stage II, base level 2", "Stage III, base level 3",
                    "Stage III, the ram on the plate"),
          "condenser": ("Stage I, level 1 to 5", "Stage II, level 6 to 14", "Stage III, level 15 and up",
                        "Stage III, full, three jewels")}
LABELS = {"forge": ("Stage I", "Stage II", "Stage III", "III, ram down"),
          "condenser": ("Stage I", "Stage II", "Stage III", "III, full")}
FULL_VIEWS = ("front", "side", "three")
CUT_VIEWS = ("court", "front", "side", "back", "three", "high")


def toward(at_, target):
    """The game's camera behind a player at `at_` (across, in), turned to `target`: the start zoom and pitch."""
    import lantern_row_look as look
    pitch, focus = math.radians(20.0), Vector((at_[0], -at_[1], 3.0 + look.FOCUS))
    flat = Vector((target[0] - at_[0], -(target[1] - at_[1]), 0.0)).normalized()
    eye = focus - flat * math.cos(pitch) * look.ZOOM + Vector((0, 0, 1)) * math.sin(pitch) * look.ZOOM
    return tuple(eye), tuple(focus)


def review(out, machine, fast):
    import bpy
    from bpy_extras.object_utils import world_to_camera_view
    import base_kit as base
    import base_plan as plan
    import blcommon as bl
    import lantern_row_look as look
    import rook_sheet as rs

    level = 3
    spot = base.FORGE if machine == "forge" else base.CONDENSER
    name = "Forge" if machine == "forge" else "Condenser"
    made_rows = plan.machines
    plan.machines = lambda lv=1: [row for row in made_rows(lv)
                                  if not (row[0] == "SleepingStone" and f"the {name}'s place" in row[5])]
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

    x, inward = spot
    inner = 1.0 if x < 0 else -1.0                         # toward the plot's middle line
    mid = (x, -inward, 6.0)
    views = {"court": toward((inner * -16.0, 36.0), spot),  # a player at the court's back, turned to it
             "way": toward((x + inner * 12.0, inward - 16.0), spot),   # walking up to it from the main line
             "front": ((x, -inward + 20.0, 8.0), mid),
             "side": ((x + inner * 18.0, -inward, 8.0), mid),
             "back": ((x, -inward - 16.0, 8.0), mid),
             "three": ((x + inner * 13.0, -inward + 13.0, 9.0), mid),
             "high": ((x + inner * 10.0, -inward + 10.0, mid[2] + 13.0), mid),
             "close": ((x, -inward + 9.0, 12.6), (x, -inward, 12.4)) if machine == "forge"   # the gears
             else ((x, -inward + 12.0, 5.5), (x, -inward, 5.0))}                           # the cups
    w, h = look.SIZE
    boxes, tris, counts = {}, {}, {}
    near = 6.5                                             # the machine's own reach from its place

    def world_box(o):
        corners = [o.matrix_world @ Vector(c) for c in o.bound_box]
        return [Vector([min(c[i] for c in corners) for i in range(3)]), Vector([max(c[i] for c in corners) for i in range(3)])]

    bpy.context.view_layer.update()                        # the placed pieces' world matrices, before reading them
    standing = [(o, world_box(o)) for o in scene.objects if o.type == "MESH"]

    def blockers(eye, target):
        """The yard's standing meshes between a close view's eye and the machine: hidden for that view only. The
        court's and the walk-up's views keep everything, as the player sees it."""
        eye, target = Vector(eye), Vector(target)
        found, steps = [], 80
        for o, (lo, hi) in standing:
            if hi.z < 1.2:
                continue
            for i in range(steps + 1):
                p = eye.lerp(target, i / steps)
                if Vector((p.x - target.x, p.y - target.y)).length < near:
                    break
                if all(lo[k] - 0.5 <= p[k] <= hi[k] + 0.5 for k in range(3)):
                    found.append(o)
                    break
        return found

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

    for key, stage, how in KEYS[machine]:
        mesh, counts[key] = whole(machine, stage, **how)
        tris[key] = mesh.whole().tris()
        data = mesh.whole().to_object(f"{name}{key}", kit_mat)
        obj = bpy.data.objects.new(f"{name}{key}", data)
        obj.location = (x, -inward, 0.0)
        scene.collection.objects.link(obj)
        bpy.context.view_layer.update()
        for view, (eye, target) in views.items():
            scene.camera = plan.camera(scene, f"Cam{key}{view}", eye, target)
            path = out / f"{machine}_{key}_{view}.png"
            hidden = [] if view in ("court", "way") else blockers(eye, target)
            for o in hidden:
                o.hide_render = True
            rs.save(look.finish(look.render_linear(scene, path.with_suffix(".exr")), d), path)
            path.with_suffix(".exr").unlink(missing_ok=True)
            for o in hidden:
                o.hide_render = False
            if view in CUT_VIEWS:
                pts = [world_to_camera_view(scene, scene.camera, obj.matrix_world @ v.co) for v in obj.data.vertices]
                boxes[f"{key} {view}"] = (min(p.x for p in pts) * w, min((1 - p.y) for p in pts) * h,
                                          max(p.x for p in pts) * w, max((1 - p.y) for p in pts) * h)
                silhouette(obj, out / f"black_{machine}_{key}_{view}.png")
        bpy.data.objects.remove(obj)
        bpy.data.meshes.remove(data)
    (out / f"{machine}_review.json").write_text(json.dumps(dict(boxes=boxes, tris=tris, counts=counts)),
                                                encoding="utf-8")


NOTES = {
    "forge": "The Gear Train (research's pick, AR36): the head widens into a lintel 7.6 across on the horns' shoulders, "
             "carrying four ForgeGear in a row, each meshing the next (Stage II); the lintel's ends step up to carry "
             "two more, each over an outer gear and meshing it alone, and each horn takes three bone clamps (Stage "
             "III). Every gear is void stone with a vein of the void's light and an unlit bone hub, Stage I's two "
             "included; they turn with the ram, each against the ones it meshes (the last column: the ram on the "
             "plate). The seat, the plate and the ram stay Stage I's.",
    "condenser": "The Climbing Comb (research's pick, AR36): cups climb the horns' outer sides on six-sided plates "
                 "facing the gate, three a side at Stage II, five at III, each chain a cup below the block's so the "
                 "top stays open. The comb, the core and the horns stay Stage I's. The cups fill by height, the "
                 "climbing ones with the comb's row at theirs, so the lit height is the fill; the last column is "
                 "Stage III full, three cups holding a jewel (the builder tints them in the jewel type's colour).",
}


def sheet(out, machine):
    """The machine's sheet, its stages side by side from the shots on disk, in a Blender of its own."""
    import numpy as np
    import lantern_row_look as look
    import rook_sheet as rs
    import ui_sheet as ui

    saved = json.loads((out / f"{machine}_review.json").read_text(encoding="utf-8"))
    boxes, tris, counts = {tuple(k.split(" ")): v for k, v in saved["boxes"].items()}, saved["tris"], saved["counts"]
    w, h = look.SIZE
    said = {"court": "from the court, as the player sees it", "front": "head-on from the gate's side, 20 away",
            "side": "from the plot's middle line's side, 18 away", "back": "from behind, 16 away",
            "three": "three-quarter, from the front and the middle line's side",
            "high": "from above, about 40 degrees down, three-quarter"}
    title = "the Forge" if machine == "forge" else "the Stone Condenser"
    keys = [k for k, _, _ in KEYS[machine]]
    titles = TITLES[machine]
    n = len(keys)

    def shot(k, view):
        return rs.load(out / f"{machine}_{k}_{view}.png")

    def blackened(k, view):
        px = rs.load(out / f"black_{machine}_{k}_{view}.png")
        ink = np.ones_like(px)
        ink[..., :3] = 1.0 - px[..., 3:4]
        return ink

    def union(view):
        b = [boxes[(k, view)] for k in keys]
        return tuple(int(v) for v in (max(min(q[0] for q in b) - 8, 0), max(min(q[1] for q in b) - 8, 0),
                                      min(max(q[2] for q in b) + 8, w), min(max(q[3] for q in b) + 8, h)))

    def crop(px, box):
        return px[box[1]:box[3], box[0]:box[2]]

    unions = {view: union(view) for view in CUT_VIEWS}
    fulls = {view: [crop(shot(k, view), unions[view]) for k in keys] for view in CUT_VIEWS}
    names = LABELS[machine]
    cups = (" Cups: " + ", ".join(f"{s} {counts[k]}" for s, k in zip(names[:3], keys[:3])) + ".") \
        if machine == "condenser" else ""
    notes = [NOTES[machine],
             "In the base kit's colours, in the yard at base level 3 under the place's dusk, rendered in Blender; "
             "nothing is seen in Studio. Triangles, a stage whole before the drawn edge's hull: "
             + ", ".join(f"{s} {tris[k]:,}" for s, k in zip(names[:3], keys[:3])) + "." + cups]
    lines = [ln for note in notes for ln in textwrap.wrap(note, 230)]
    gap = 16
    cw, ch = round(w / 2), round(h / 2)
    small = 26 + 64 + gap + 128 + gap + 20
    widths = [sum(px.shape[1] for px in fulls[v]) + (n + 1) * gap for v in FULL_VIEWS]
    cuts = [n * (2 * round(128 * fulls[v][0].shape[1] / fulls[v][0].shape[0]) + 8 + 2 * gap) + 2 * gap
            for v in CUT_VIEWS]
    width = max(n * cw + (n + 1) * gap, *widths, *cuts, 1300)
    height = 48 + 3 * (ch + 34) + sum(max(px.shape[0] for px in fulls[v]) + 42 for v in FULL_VIEWS) \
        + len(CUT_VIEWS) * small + 34 + len(lines) * 19 + 24
    ui.K = 1
    page = ui.Sheet(width, height, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 14, 20, f"Grow your Anime, {title}'s three stages (AR36, the kit pieces)", "#EDE6D6", bold=0.2)
    y = 48
    close = "the head close, 9 away: the gears against the void's light" if machine == "forge" \
        else "the comb close, 12 away: the climbing cups"
    for view, caption in (("court", "a player at the court's back turned to it, at a phone's 480 by 270"),
                          ("way", "a player walking up to it from the main line, turned to it"), ("close", close)):
        for i, k in enumerate(keys):
            x0 = gap + i * (cw + gap)
            t.text(x0, y, 14, f"{titles[i]}: {caption}" if i == 0 else titles[i], "#B4AC9C")
            rs.paste(page.px, rs.shrink(shot(k, view), 1 / 2), x0, y + 22)
        y += ch + 34
    for view in FULL_VIEWS:
        t.text(gap, y, 14, f"{said[view]}, at its own size on a 960 by 540", "#B4AC9C")
        x0 = gap
        for px in fulls[view]:
            rs.paste(page.px, px, x0, y + 22)
            x0 += px.shape[1] + gap
        y += max(px.shape[0] for px in fulls[view]) + 42
    for view in CUT_VIEWS:
        t.text(gap, y, 14, f"{said[view]}: cut at one scale for all, 64 and 128 px tall over the dark, and in black",
               "#B4AC9C")
        x0 = gap
        for i, k in enumerate(keys):
            left, tall = x0, fulls[view][i].shape[0]
            ink = crop(blackened(k, view), unions[view])
            for px in (rs.shrink(fulls[view][i], 64 / tall), rs.shrink(ink, 64 / tall)):
                rs.paste(page.px, px, x0, y + 26)
                x0 += px.shape[1] + 8
            x0 = left
            for px in (rs.shrink(fulls[view][i], 128 / tall), rs.shrink(ink, 128 / tall)):
                rs.paste(page.px, px, x0, y + 26 + 64 + gap)
                x0 += px.shape[1] + 8
            t.text(left, y + 26 + 64 + 128 + 2 * gap - 6, 13, LABELS[machine][i], "#EDE6D6")
            x0 += 2 * gap
        y += small
    y += 14
    for i, ln in enumerate(lines):
        t.text(gap, y + i * 19, 14, ln, "#B4AC9C")
    for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
        rs.paste(page.px, layer, 0, 0)
    rs.save(page.px, out / f"{machine}_stages.png")
    print("triangles:", tris, "cups:", counts)


def main():
    import blcommon as bl
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    machine = "condenser" if "condenser" in args else "forge"
    if "sheet" in args:
        sheet(out, machine)
    else:
        review(out, machine, "fast" in args)


if __name__ == "__main__":
    main()
