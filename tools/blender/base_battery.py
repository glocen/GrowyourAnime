"""AR34: the battery's Stages II and III, two directions for how the battery grows, in grey beside Stage I
(docs/asset-requests.md, AR34). The battery takes the base's level: Stage I at level 1, II at 2, III at 3.

Both directions keep Stage I's rack with AR19's note made: the copper bar is a groove of void stone with the current's
line in it, and the posts are void stone, squared, their insulators gone. BatteryCell is unchanged, and each cell's glow
is its share of the charge.

  A, the Rising Stack   the bank climbs: the cells stand in tiers of two between two uprights of void stone, and the
                        fill lights tier by tier from the bottom, a gauge. Stage III's uprights bend in to two points
                        and hold a bead of the void's light inside the fork, below the tips.
  B, the Ridge          the bank stays on today's eight seats, and a ridge of uneven void-stone blades rises behind it,
                        each with a vein of the void's light stopping short of its tip.

The review: each stage in the yard at base level 3, from a player in the court turned to the battery, head-on, from a
side and three-quarter, cut small and in black (the content check's conditions on the plan, 2026-11-17):
blender.exe -b --factory-startup --python-exit-code 1 --python tools/blender/base_battery.py -- <abs out_dir> [fast]
"""

import math
import sys
import textwrap
from pathlib import Path

import bpy
import numpy as np
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_kit as base  # noqa: E402
import base_machines as bm  # noqa: E402
import base_plan as plan  # noqa: E402
import blcommon as bl  # noqa: E402
import lantern_row_kit as kit  # noqa: E402
import lantern_row_look as look  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
from base_mill import Mesh, at, put  # noqa: E402

WIDE, DEEP, _ = bm.BANK
SEAT = bm.SEAT
GREY = {"steel": "concrete", "girder": "concrete", "abyss": "concrete", "yellow": "concrete", "copper": "concrete",
        "bone": "ceramic"}
STAGES = {"A": "the Rising Stack", "B": "the Ridge"}
LIT = {1: 1, 2: 3, 3: 5}               # the review's charge: cells lit, of the 2, 4 and 8 a stage holds


class Swap:
    """While it's open, every swatch a shape asks for is drawn in its stand-in."""

    def __init__(self, table):
        self.table = table

    def __enter__(self):
        self.own = kit.sw_uv
        kit.sw_uv = lambda name, occ, t: self.own(self.table.get(name, name), occ, t)

    def __exit__(self, *_):
        kit.sw_uv = self.own


# --- what every stage keeps: the rack, AR19's note made ------------------------------------------------------------------

def rack(m, seats):
    """The deck on the stand-in's footprint, its dark seats, the groove of void stone with the current's line, and the
    two posts of void stone with their lights."""
    m.box((WIDE + 0.3, DEEP + 0.3, 0.3), (0, 0, 0.15), "concrete", ink=True)
    m.box((WIDE, DEEP, 0.3), (0, 0, 0.45), "girder", ink=True)
    for x, y in seats:
        m.box((1.24, 1.5, 0.05), (x, y, SEAT + 0.025), "dark")
    m.box((WIDE - 0.5, 0.34, 0.14), (0, 0, SEAT + 0.07), "abyss")
    m.box((WIDE - 0.9, 0.12, 0.05), (0, 0, SEAT + 0.165), "power")
    for sx in (-1, 1):
        x = sx * (WIDE / 2 - 0.22)
        m.box((0.42, 0.42, 2.45 - SEAT), (x, 0, (SEAT + 2.45) / 2), "abyss", ink=True)
        m.box((0.24, 0.24, 0.2), (x, 0, 2.55), "power")


# --- A, the Rising Stack --------------------------------------------------------------------------------------------------

PITCH = 2.45            # a tier's rise: a cell is 2.16 high with its terminal
POST = 1.6              # the uprights' middles, across
STACK_Y = -0.95         # the stack stands on Stage I's two seats, the back row
TIERS = {2: 2, 3: 4}


def stack_seats(stage):
    """A's seats in the order they fill: the bottom tier first, left to right."""
    return [(sx * 0.75, STACK_Y, SEAT + k * PITCH) for k in range(TIERS[stage]) for sx in (-1, 1)]


def stack(stage):
    m = Mesh()
    rack(m, [(-0.75, STACK_Y), (0.75, STACK_Y)])
    inner = 2 * POST - 0.4
    top = SEAT + (TIERS[stage] - 1) * PITCH + 2.28
    for k in range(1, TIERS[stage]):
        m.box((inner, 1.5, 0.12), (0, STACK_Y, SEAT + k * PITCH - 0.06), "bone", ink=True)   # a tier's shelf, a tie
    m.box((inner, 1.5, 0.16), (0, STACK_Y, top + 0.08), "bone", ink=True)
    for sx in (-1, 1):
        m.box((0.4, 1.5, top + 0.16 - SEAT), (sx * POST, STACK_Y, (SEAT + top + 0.16) / 2), "abyss", ink=True)
        for sy in (-1, 1):                      # a point at the front and one at the back: a fork from the side too
            if stage == 2:
                spread = (0.4, 0.55)
                pts = [(sx * POST, STACK_Y + sy * spread[0], top + 0.16),
                       (sx * (POST - 0.1), STACK_Y + sy * spread[1], top + 1.0)]
                radii = [0.2, 0.03]
            else:
                spread = (0.4, 0.45, 0.55, 0.62)
                xs = (POST, POST + 0.15, POST - 0.4, 0.55)
                zs = (top + 0.16, top + 1.1, top + 2.1, top + 2.65)
                pts = [(sx * x_, STACK_Y + sy * s_, z_) for x_, s_, z_ in zip(xs, spread, zs)]
                radii = [0.2, 0.22, 0.14, 0.03]
            bm.horn(m, pts, radii, "abyss", flat=(0.0, 1.0, 0.0), deep=1.5)
    if stage == 3:
        bm.shard(m, (0.0, STACK_Y, top + 1.5), 0.4, 1.3, "void")   # held in the fork, its top under the tips
    return m


# --- B, the Ridge ---------------------------------------------------------------------------------------------------------

RIDGE_Y = -1.95         # the blades' plane, behind the back row of cells
# Each blade: its foot across, its height, how far its tip leans across, and its half width at the root. Uneven, each
# rooted on its own, nearly upright, never a crown, a fan or a hand; the tallest's neighbour at least 80% of it (the
# content check's conditions, 2026-11-17).
RIDGE = {2: [(-2.3, 4.2, -0.3, 0.5), (0.2, 6.6, 0.1, 0.62), (2.3, 5.4, 0.3, 0.42)],
         3: [(-2.5, 3.6, -0.3, 0.38), (-1.35, 5.6, -0.2, 0.5), (0.05, 8.6, -0.05, 0.6), (1.3, 10.0, 0.12, 0.55),
             (2.5, 7.2, 0.3, 0.44)]}


def ridge(stage):
    m = Mesh()
    rack(m, bm.SEATS)
    for x, high, lean, w in RIDGE[stage]:
        pts = [(x, RIDGE_Y, SEAT), (x + lean * 0.4, RIDGE_Y, SEAT + high * 0.55), (x + lean, RIDGE_Y, SEAT + high)]
        radii = [w, w * 0.75, 0.03]
        bm.horn(m, pts, radii, "abyss", flat=(0.0, 1.0, 0.0), deep=0.4)
        t = 0.35                                                    # the vein ends 35% up the last stretch
        end = tuple(a + (b - a) * t for a, b in zip(pts[1], pts[2]))
        bm.vein(m, [pts[0], pts[1], end], [radii[0], radii[1], radii[1] + (radii[2] - radii[1]) * t],
                (x, RIDGE_Y + 10.0, SEAT + high * 0.5), r=0.08)
    return m


def ridge_seats(stage):
    return [(x, y, SEAT) for x, y in bm.SEATS[:bm.CELLS_AT[stage]]]


# --- a stage whole ---------------------------------------------------------------------------------------------------------

def whole(body, seats, lit):
    """The stage's body with its cells, the first `lit` of them lit and the rest at the empty glow's stand-in."""
    m = Mesh()
    put(m, body, at(0, 0, 0))
    with Swap({}):
        on = bm.battery_cell().mesh
    with Swap({"power": "yellow"}):
        off = bm.battery_cell().mesh
    for i, (x, y, z) in enumerate(seats):
        put(m, on if i < lit else off, at(x, y, z))
    return m


def build():
    made = {"I": whole(stage_one(), [(x, y, SEAT) for x, y in bm.SEATS[:2]], LIT[1])}
    for key, (body, seats) in {"A": (stack, stack_seats), "B": (ridge, ridge_seats)}.items():
        for stage in (2, 3):
            with Swap(GREY):
                shape = body(stage)
            made[f"{key}{'I' * stage}"] = whole(shape, seats(stage), LIT[stage])
    return made


def stage_one():
    m = Mesh()
    rack(m, bm.SEATS)
    return m


# --- the yard, the views and the sheets ---------------------------------------------------------------------------------

LEVEL = 3
AT = base.BATTERY                                 # across, in


def yard(out: Path, fast):
    """base_plan's look at level 3, the battery taken out."""
    made = plan.machines
    plan.machines = lambda level=1: [row for row in made(level) if row[0] not in ("BatteryRack", "BatteryCell")]
    d = look.DIRECTIONS["M"]
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1], azimuth=d.get("glow_az", 0.0),
                    away=look.srgb(d["fog_away"]) if "fog_away" in d else None)
    scene = bl.reset_scene()
    base.write_pictures(out / "maps")
    y = plan.Yard(scene, LEVEL, out / "maps")
    y.plot(0.0, 1)
    y.plot(plan.STRIP, -1)
    y.kit.block("Strip", (3 * plan.PLOT, plan.STRIP, 0.4), (0, plan.STRIP / 2, -0.22), y.stone)
    y.kit.block("Ground", (5 * plan.PLOT, 4 * plan.PLOT, 0.4), (0, plan.STRIP / 2, -0.3), y.flat["ground"])
    y.person((AT[0] + 5.2, -(AT[1] - 1.0)))                            # a player beside it, for its size
    for obj in y.kit.pieces:
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
    return scene, y, d


def toward(at_, target):
    """The game's camera behind a player at `at_` (across, in), turned to `target`: the start zoom and pitch."""
    pitch, focus = math.radians(20.0), Vector((at_[0], -at_[1], 3.0 + look.FOCUS))
    flat = Vector((target[0] - at_[0], -(target[1] - at_[1]), 0.0)).normalized()
    eye = focus - flat * math.cos(pitch) * look.ZOOM + Vector((0, 0, 1)) * math.sin(pitch) * look.ZOOM
    return tuple(eye), tuple(focus)


def views():
    x, inward = AT
    mid = (x, -inward, 5.5)
    return {"court": toward((16.0, 36.0), AT),                         # a player at the court's back, turned to it
            "way": toward((43.0, 56.0), AT),                            # on the way to the right side's back bay
            "front": ((x, -(inward - 18.0), 7.0), mid),                 # head-on from the court's side
            "side": ((x - 18.0, -inward, 7.0), mid),                    # from the generator's side
            "far": ((x + 18.0, -inward, 7.0), mid),                     # from the side wall's side
            "back": ((x, -(inward + 12.0), 6.0), mid),                  # from behind, short of the Condenser's stone
            "three": ((x - 13.0, -(inward - 13.0), 7.0), mid)}          # three-quarter, front and the generator's side


CUTS = ("front", "side", "far", "back", "three")    # cut small and in black
FULL = ("front", "side", "three")                   # at their own size too


class Shots:
    def __init__(self, out, scene, y, d):
        self.out, self.scene, self.yard, self.d = out, scene, y, d
        self.views = views()
        self.made, self.tris, self.boxes, self.black = {}, {}, {}, {}

    def take(self, key, mesh):
        data = mesh.whole().to_object(f"Battery{key}", self.yard.stock.mats["Kit"])
        self.tris[key] = mesh.whole().tris()
        obj = bpy.data.objects.new(f"Battery{key}", data)
        obj.location = (AT[0], -AT[1], 0.0)
        self.scene.collection.objects.link(obj)
        bpy.context.view_layer.update()
        for name, (eye, target) in self.views.items():
            self.scene.camera = plan.camera(self.scene, f"Cam{key}{name}", eye, target)
            path = self.out / f"battery_{key}_{name}.png"
            px = look.finish(look.render_linear(self.scene, path.with_suffix(".exr")), self.d)
            path.with_suffix(".exr").unlink(missing_ok=True)
            rs.save(px, path)
            self.made[(key, name)] = px
            if name in CUTS:
                self.boxes[(key, name)] = self.frame_box(obj)
                self.black[(key, name)] = self.silhouette(obj, self.out / f"_black_{key}_{name}.png")
        bpy.data.objects.remove(obj)
        bpy.data.meshes.remove(data)

    def frame_box(self, obj):
        w, h = look.SIZE
        pts = [world_to_camera_view(self.scene, self.scene.camera, obj.matrix_world @ v.co) for v in obj.data.vertices]
        xs, ys = [p.x * w for p in pts], [(1 - p.y) * h for p in pts]
        return min(xs), min(ys), max(xs), max(ys)

    def silhouette(self, obj, path):
        scene, r = self.scene, self.scene.render
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
        black = np.ones_like(px)
        black[..., :3] = 1.0 - px[..., 3:4]
        path.unlink()
        return black


def crop(px, box):
    x0, y0, x1, y1 = (int(v) for v in box)
    return px[max(y0, 0):y1, max(x0, 0):x1]


def union(shots, keys, name):
    b = [shots.boxes[(k, name)] for k in keys]
    return (min(v[0] for v in b) - 8, min(v[1] for v in b) - 8, max(v[2] for v in b) + 8, max(v[3] for v in b) + 8)


NOTES = {
    "A": "The bank climbs. At Stage II two uprights of void stone rise from the deck's ends of Stage I's two seats, and "
         "the four cells stand in two tiers of two, a bone shelf across each tier, inside the uprights; the uprights "
         "end in short points. At Stage III the uprights carry four tiers of two, and bend in to points, apart, "
         "holding a bead of the void's light inside the fork, its top under the tips; each upright forks front and back "
         "too, so from the side the bead is held in a notch. The fill lights tier by tier from "
         "the bottom, a gauge: the table gives each stage's seats in that order. The deck's other seats go.",
    "B": "A ridge rises behind the bank. The cells keep today's eight seats and their order. At Stage II three blades of "
         "void stone rise from the deck's back edge, uneven at 4.2, 6.6 and 5.4 high and leaning a little apart, each "
         "with a vein of the void's light stopping short of its tip. At Stage III five, at 3.6, 5.6, 8.6, 10 and 7.2, "
         "the tallest off the middle, so the ridge peaks to one side. From the court the lit cells stand in front of "
         "the dark stone.",
}
SHARED = ("Both: Stage I is the battery as it stands with AR19's note made, the copper bar a groove of void stone with the "
          "current's line in it, the posts void stone, squared, their insulators gone. BatteryCell is unchanged. The "
          "footprint stays inside 6.6 by 4.6. The charge shown: Stage I 1 cell lit of 2, Stage II 3 of 4, Stage III 5 "
          "of 8; an empty cell's line is drawn in the kit's dull yellow, for the game's empty glow. Grey blocks in the "
          "base kit's swatches, with the void's light and the cells lit, in the yard at base level 3 under the place's "
          "dusk, a player beside it, rendered in Blender; nothing is seen in Studio.")
TITLES = ("Stage I, base level 1, as it stands", "Stage II, base level 2", "Stage III, base level 3")
SAID = {"front": "head-on from the court's side, 18 away", "side": "from the generator's side, 18 away",
        "three": "three-quarter, from the front and the generator's side", "far": "from the side wall's side",
        "back": "from behind, 12 away"}


def sheet(out, key, shots):
    gap, (w, h) = 16, look.SIZE
    cw, ch = round(w * 2 / 3), round(h * 2 / 3)
    keys = ["I", f"{key}II", f"{key}III"]
    unions = {name: union(shots, keys, name) for name in CUTS}
    fulls = {name: [crop(shots.made[(k, name)], unions[name]) for k in keys] for name in CUTS}
    lines = [ln for n in (NOTES[key], SHARED + " Triangles, a stage whole, before the drawn edge's hull: "
                          + ", ".join(f"Stage {k[-3:] if k != 'I' else 'I'} {shots.tris[k]:,}" for k in keys) + ".")
             for ln in textwrap.wrap(n, 230)]
    small = 26 + 64 + gap + 128 + gap + 20
    widths = [sum(px.shape[1] for px in fulls[name]) + 4 * gap for name in FULL]
    cut_w = 3 * (2 * round(128 * (unions["front"][2] - unions["front"][0]) / (unions["front"][3] - unions["front"][1]))
                 + 8 + 2 * gap)
    width = max(3 * cw + 4 * gap, *widths, cut_w + 2 * gap, 1200)
    height = 48 + 2 * (ch + 34) + sum(max(px.shape[0] for px in fulls[n]) + 34 + 8 for n in FULL) + len(CUTS) * small + 34 \
        + len(lines) * 19 + 24
    page = ui.Sheet(width, height, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 14, 20, f"Grow your Anime, the battery's stages: {key}, {STAGES[key]} (AR34)", "#EDE6D6", bold=0.2)
    y = 48
    for name, said in (("court", "a player at the court's back turned to it, at a phone's 640 by 360"),
                       ("way", "a player between the right side's bays, on the way to the back one, turned to it")):
        for i, k in enumerate(keys):
            x = gap + i * (cw + gap)
            t.text(x, y, 14, f"{TITLES[i]}: {said}" if i == 0 else TITLES[i], "#B4AC9C")
            rs.paste(page.px, rs.shrink(shots.made[(k, name)], 2 / 3), x, y + 22)
        y += ch + 34
    for name in FULL:
        t.text(gap, y, 14, f"{SAID[name]}, at its own size on a 960 by 540", "#B4AC9C")
        x = gap
        for px in fulls[name]:
            rs.paste(page.px, px, x, y + 22)
            x += px.shape[1] + gap
        y += max(px.shape[0] for px in fulls[name]) + 34 + 8
    for name in CUTS:
        t.text(gap, y, 14, f"{SAID[name]}: cut at one scale for the three, 64 and 128 px tall over the dark, and in "
               f"black", "#B4AC9C")
        x = gap
        for i, k in enumerate(keys):
            x0 = x
            for px in (rs.shrink(fulls[name][i], 64 / fulls[name][i].shape[0]),
                       rs.shrink(crop(shots.black[(k, name)], unions[name]), 64 / fulls[name][i].shape[0])):
                rs.paste(page.px, px, x, y + 26)
                x += px.shape[1] + 8
            x = x0
            for px in (rs.shrink(fulls[name][i], 128 / fulls[name][i].shape[0]),
                       rs.shrink(crop(shots.black[(k, name)], unions[name]), 128 / fulls[name][i].shape[0])):
                rs.paste(page.px, px, x, y + 26 + 64 + gap)
                x += px.shape[1] + 8
            t.text(x0, y + 26 + 64 + 128 + 2 * gap - 6, 13, TITLES[i].split(",")[0], "#EDE6D6")
            x += 2 * gap
        y += small
    y += 14
    for i, ln in enumerate(lines):
        t.text(gap, y + i * 19, 14, ln, "#B4AC9C")
    for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
        rs.paste(page.px, layer, 0, 0)
    rs.save(page.px, out / f"battery_{key}.png")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    scene, y, d = yard(out, "fast" in args)
    shots = Shots(out, scene, y, d)
    for key, mesh in build().items():
        shots.take(key, mesh)
    ui.K = 1
    for key in STAGES:
        sheet(out, key, shots)
    print("triangles:", shots.tris)


if __name__ == "__main__":
    main()
