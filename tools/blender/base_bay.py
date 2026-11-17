"""AR33: the extraction bays' Stages II and III, two directions for how a bay grows, in grey beside Stage I
(docs/asset-requests.md, AR33, "The two directions, planned").

blender.exe -b --factory-startup --python-exit-code 1 --python tools/blender/base_bay.py -- <abs out_dir> [fast]

A bay grows on its outer side and up, never over its inner half or in front: the court and the gate see the worker
from there, so the growth stays behind the worker from every view in the yard. The pad stays 10 square, and the ring
and its shard stay 8 up on the outer side, so BayHalo is right at every stage.

  A, the Horned Crown   the crescent grows: at Stage II its horns rise to 12 and close over the ring higher, each
                        grows a tine from its shoulder, and a toothed ring of void stone turns round the ring; at
                        Stage III the horns reach 14.5 with a second tine and bone clamps where they branch, and a
                        second toothed ring turns the other way outside the first
  B, the Draw           rings toward the worker: at Stage II a second ring, three arcs of void stone, turns a stud in
                        front of the first, held from above by two fingers from the crescent; at Stage III a third,
                        larger, nearer still, makes an open funnel narrowing to the shard, held by two more fingers
                        from a taller crescent

Each stage stands on all six bays at base level 3, a worker's size on each, and is seen from the spawn's start camera,
from the gate through it from the Strip, and close on one bay; the close bay is also cut at 64 and 128 px and in
black. It writes each view and a sheet a direction (bay_A.png, bay_B.png).
"""

import math
import sys
import textwrap
from pathlib import Path

import bpy
import numpy as np
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_kit as base  # noqa: E402
import base_machines as bm  # noqa: E402
from base_mill import Mesh, at, prism, put  # noqa: E402
import base_plan as plan  # noqa: E402
import blcommon as bl  # noqa: E402
import lantern_row_kit as kit  # noqa: E402
import lantern_row_look as look  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402

SIDE, TOP = bm.BAY
BACK = -(SIDE / 2 - 0.55)             # the crescent's plane, on the outer side
EYE = bm.HALO[0]                      # the ring's middle, up
TO_X = Matrix.Rotation(math.pi / 2, 4, "Y")   # a part built about Z, turned so its Z lies along X, facing the worker
GREY = {"steel": "concrete", "girder": "concrete", "abyss": "concrete", "yellow": "concrete", "copper": "concrete",
        "bone": "ceramic"}
STAGES = {"A": "the Horned Crown", "B": "the Draw"}


class Grey:
    """While it's open, every swatch a block asks for is drawn in the block's grey."""

    def __enter__(self):
        self.own = kit.sw_uv
        kit.sw_uv = lambda name, occ, t: self.own(GREY.get(name, name), occ, t)

    def __exit__(self, *_):
        kit.sw_uv = self.own


# --- what every stage keeps --------------------------------------------------------------------------------------------

def ground(m):
    """The bay's deck, dais, well, inner corners and the current's outlet, as Stage I has them."""
    m.box((SIDE, SIDE, TOP), (0, 0, TOP / 2), "girder", ink=True)
    m.box((SIDE + 0.1, SIDE + 0.1, 0.1), (0, 0, 0.2), "void")
    m.lathe([(4.1, 0.16), (4.3, 0.0)], (0, 0, TOP), 12, "abyss")
    m.lathe([(3.55, 0.17), (3.85, 0.17)], (0, 0, TOP), 12, "void", caps=False)
    bm.well(m, (0, 0, TOP), 2.6)
    m.box((1.3, SIDE - 1.2, 0.6), (BACK, 0, TOP + 0.3), "abyss", ink=True)
    for sy in (-1, 1):
        bm.horn(m, [(4.35, sy * 4.35, TOP), (3.75, sy * 3.75, TOP + 1.7)], [0.42, 0.05], "abyss", flat=(sy, -1.0, 0.0))
        bm.shard(m, (3.6, sy * 3.6, TOP + 2.55), 0.24, 0.9, "void")
    bm.hoop(m, (BACK, 0, EYE), bm.HALO[1], bm.HALO[2], 0.4, 12, "abyss")
    bm.shard(m, (BACK, 0, EYE), 0.8, 3.0, "void", lean=0.55)
    m.box((0.9, 1.6, 1.0), (BACK + 0.3, 0, TOP + 0.5), "girder", ink=True)
    m.box((0.1, 1.0, 0.2), (BACK + 0.78, 0, TOP + 0.6), "power")


def crescent(m, arm, widths):
    """The crescent's two horns along `arm` (across the pad, up), in the crescent's plane, a vein in each. Their tips
    stay apart over the ring (the content check's condition 2: never an almond round it)."""
    t = 0.35
    end = tuple(a + (b - a) * t for a, b in zip(arm[-2], arm[-1]))
    for sy in (-1, 1):
        pts = [(BACK, sy * y, z) for y, z in arm]
        bm.horn(m, pts, widths, "abyss", flat=(1.0, 0.0, 0.0), deep=0.75)
        bm.vein(m, pts[:-1] + [(BACK, sy * end[0], end[1])], widths[:-1] + [widths[-2] + (widths[-1] - widths[-2]) * t],
                (BACK, 0, 5.5), r=0.08)


def tine(m, sy, pts, widths):
    bm.horn(m, [(BACK, sy * y, z) for y, z in pts], widths, "abyss", flat=(1.0, 0.0, 0.0), deep=0.75)


def notched(m, r, teeth, hole, x=BACK, thick=0.35, tooth=(0.3, 0.36)):
    """A toothed ring of void stone round the ring, in the crescent's plane: its web from `hole` out to `r`, and
    short, square-ended teeth, as long as they're wide (the content check's condition 6: never tapered or pointed)."""
    g = Mesh()
    bm.hoop(g, (0, 0, 0), hole, r + 0.02, thick, max(teeth, 12), "abyss", lying=True)
    out_, wide = tooth
    for k in range(teeth):
        a = math.tau * (k + 0.5) / teeth
        o, s = Vector((math.cos(a), math.sin(a), 0.0)), Vector((-math.sin(a), math.cos(a), 0.0))
        rim = [o * r - s * wide / 2, o * (r + out_) - s * wide / 2, o * (r + out_) + s * wide / 2, o * r + s * wide / 2]
        prism(g, rim, thick, "abyss", o * (r + out_ / 2))
    put(m, g, at(x, 0, EYE) @ TO_X)


def arcs(m, x, r, width, count=3, span=100.0, phase=0.0):
    """A ring of `count` arcs of void stone round the shard, each `span` degrees and tapered at its ends, the first
    centred `phase` degrees from the top: a ring that shows its turning. Plain: nothing on it (condition 5)."""
    n = 6
    for k in range(count):
        a0 = math.radians(phase + 360.0 * k / count - span / 2)
        pts = [(x, r * math.sin(a0 + math.radians(span) * i / (n - 1)), EYE + r * math.cos(a0 + math.radians(span) * i / (n - 1)))
               for i in range(n)]
        bm.horn(m, pts, [0.05, width * 0.85, width, width, width * 0.85, 0.05], "abyss", flat=(1.0, 0.0, 0.0), deep=0.9)


def on_ring(x, r, deg):
    """The point `deg` degrees from the top of a ring of radius `r` in the plane at `x`."""
    a = math.radians(deg)
    return x, r * math.sin(a), EYE + r * math.cos(a)


# --- A, the Horned Crown -----------------------------------------------------------------------------------------------

def crown(stage):
    m = Mesh()
    ground(m)
    if stage == 2:
        crescent(m, [(3.7, TOP + 0.5), (4.9, 3.6), (4.6, 7.6), (3.5, 10.5), (2.1, 12.0)], [0.8, 0.74, 0.6, 0.4, 0.05])
        for sy in (-1, 1):                               # a tine from each shoulder, up and out
            tine(m, sy, [(4.55, 7.3), (4.85, 9.4), (4.97, 11.0)], [0.46, 0.32, 0.05])
        notched(m, 2.75, 16, 2.15)
    else:
        crescent(m, [(3.7, TOP + 0.5), (4.95, 4.0), (4.85, 8.5), (3.8, 12.2), (2.3, 14.5)], [0.9, 0.82, 0.68, 0.46, 0.05])
        for sy in (-1, 1):
            tine(m, sy, [(4.8, 8.3), (4.95, 10.6), (4.98, 12.4)], [0.5, 0.34, 0.05])
            tine(m, sy, [(3.75, 12.3), (4.2, 14.0), (4.5, 15.6)], [0.42, 0.3, 0.05])
            for y, z in ((4.82, 8.4), (3.75, 12.3)):     # a bone clamp where each tine branches
                m.box((0.9, 0.8, 0.7), (BACK, sy * y, z), "bone", ink=True)
        notched(m, 2.75, 16, 2.15)
        notched(m, 3.55, 22, 3.15, x=BACK - 0.05)
    return m


# --- B, the Draw -------------------------------------------------------------------------------------------------------

def finger(m, sy, start, mid, ring_x, ring_r, deg):
    """A finger from the crescent's horn to a ring's upper side, and a bone clamp on the ring: two a ring, never at
    its quarter points (condition 9)."""
    cx, cy, cz = on_ring(ring_x, ring_r + 0.3, deg)
    bm.horn(m, [(BACK, sy * start[0], start[1]), (mid[0], sy * mid[1], mid[2]), (cx, sy * cy, cz)], [0.34, 0.26, 0.2],
            "abyss", flat=(0.4, 0.0, 1.0))
    x, y, z = on_ring(ring_x, ring_r + 0.12, deg)
    m.box((0.5, 0.55, 0.55), (x, sy * y, z), "bone", ink=True)


def draw(stage):
    m = Mesh()
    ground(m)
    one, two = (BACK + 1.1, 2.35, 0.24), (BACK + 1.9, 2.95, 0.28)
    if stage == 2:
        crescent(m, [(3.7, TOP + 0.5), (4.9, 3.6), (4.6, 7.4), (3.6, 10.2), (2.2, 11.2)], [0.8, 0.74, 0.6, 0.4, 0.05])
        arcs(m, one[0], one[1], one[2])
        for sy in (-1, 1):
            finger(m, sy, (3.8, 9.9), (BACK + 0.6, 2.9, 10.6), one[0], one[1], 40.0)
    else:
        crescent(m, [(3.7, TOP + 0.5), (4.95, 3.8), (4.85, 8.0), (4.0, 11.6), (2.2, 13.5)], [0.9, 0.82, 0.68, 0.46, 0.05])
        arcs(m, one[0], one[1], one[2])
        arcs(m, two[0], two[1], two[2], phase=60.0)
        for sy in (-1, 1):
            finger(m, sy, (4.2, 10.6), (BACK + 0.6, 3.0, 11.0), one[0], one[1], 40.0)
            finger(m, sy, (4.75, 9.0), (BACK + 1.0, 4.0, 9.8), two[0], two[1], 60.0)
    return m


BUILD = {"A": crown, "B": draw}


# --- the yard, the views and the sheets ----------------------------------------------------------------------------

LEVEL = 3                                     # all six bays open


def yard_without_bays(out: Path, fast):
    """base_plan's look at level 3, its bays taken out (their halos stay)."""
    made = plan.machines
    plan.machines = lambda level=1: [row for row in made(level) if row[0] != "Bay"]
    d = look.DIRECTIONS["M"]
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1], azimuth=d.get("glow_az", 0.0),
                    away=look.srgb(d["fog_away"]) if "fog_away" in d else None)
    scene = bl.reset_scene()
    base.write_pictures(out / "maps")
    yard = plan.Yard(scene, LEVEL, out / "maps")
    yard.plot(0.0, 1)
    yard.plot(plan.STRIP, -1)
    yard.kit.block("Strip", (3 * plan.PLOT, plan.STRIP, 0.4), (0, plan.STRIP / 2, -0.22), yard.stone)
    yard.kit.block("Ground", (5 * plan.PLOT, 4 * plan.PLOT, 0.4), (0, plan.STRIP / 2, -0.3), yard.flat["ground"])
    yard.person((base.SPAWN[0], -base.SPAWN[1]))
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
    return scene, yard, d


def toward(at, target):
    """The game's camera behind a player at `at` (across, in), turned to `target` (across, in): the start zoom and
    pitch, as base_plan's behind()."""
    pitch, focus = math.radians(20.0), Vector((at[0], -at[1], 3.0 + look.FOCUS))
    flat = Vector((target[0] - at[0], -(target[1] - at[1]), 0.0)).normalized()
    eye = focus - flat * math.cos(pitch) * look.ZOOM + Vector((0, 0, 1)) * math.sin(pitch) * look.ZOOM
    return tuple(eye), tuple(focus)


def views():
    gi = base.ROW
    return {"home": plan.behind((base.SPAWN[0], -base.SPAWN[1]), -1),
            "gate": plan.behind((0, plan.STRIP / 2), -1),
            "row": toward((-4.0, 36.0), (-46.0, 62.0)),     # a player in the court, turned to the left side's three
            "court": ((-(base.OUTER - 19.5), -gi, 8.5), (-base.OUTER, -gi, 7.0))}   # head-on from the court


class Shots:
    def __init__(self, out, scene, yard, d):
        self.out, self.scene, self.yard, self.d = out, scene, yard, d
        self.views = views()
        self.made, self.tris, self.boxes, self.black = {}, {}, {}, {}

    def take(self, key, mesh):
        data = mesh.whole().to_object(f"Bay{key}", self.yard.stock.mats["Kit"])
        self.tris[key] = mesh.whole().tris()
        objs = []
        for i, (x, inward) in enumerate(plan.BAY_LOTS[:base.BAYS_AT[LEVEL]]):
            obj = bpy.data.objects.new(f"Bay{key}{i}", data)
            obj.location, obj.rotation_euler = (x, -inward, 0.0), (0, 0, math.radians(0.0 if x < 0 else 180.0))
            self.scene.collection.objects.link(obj)
            objs.append(obj)
        bpy.context.view_layer.update()
        close = objs[0]                                  # the bay the court view looks at: level 1's, on the left
        for name, (eye, target) in self.views.items():
            self.scene.camera = plan.camera(self.scene, f"Cam{key}{name}", eye, target)
            path = self.out / f"bay_{key}_{name}.png"
            px = look.finish(look.render_linear(self.scene, path.with_suffix(".exr")), self.d)
            path.with_suffix(".exr").unlink(missing_ok=True)
            rs.save(px, path)
            self.made[(key, name)] = px
            if name == "court":
                self.boxes[key] = self.frame_box(close)
                self.black[key] = self.silhouette(close, self.out / f"_black_{key}.png")
        for obj in objs:
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


def cut(px, box, tall):
    x0, y0, x1, y1 = (int(v) for v in box)
    piece = px[max(y0, 0):y1, max(x0, 0):x1]
    return rs.shrink(piece, tall / piece.shape[0])


NOTES = {
    "A": "The crescent grows. At Stage II its horns rise to 12, their tips still apart over the ring, each grows a tine "
         "from its shoulder up and out to 11, and a toothed ring of void stone (16 short, square teeth, unlit) stands "
         "round the ring. At Stage III the horns reach 14.5, a second tine branches from each horn to 15.6, bone clamps "
         "hold the branches, and a second toothed ring (22 teeth) stands outside the first. The motion, for the build: "
         "the toothed rings turn, opposite ways.",
    "B": "Rings toward the worker. At Stage II a second ring, three arcs of void stone, stands a stud in front of the "
         "first, held from above by two fingers from the crescent, its horns risen to 11.2. At Stage III a third, "
         "larger, stands nearer the worker, an open funnel narrowing to the shard, held by two more fingers from a "
         "taller crescent (13.5); no clamp at a ring's quarter points. The motion, for the build: the rings of arcs "
         "turn, opposite ways, BayHalo's motes passing through their middles."
}
SHARED = ("Both: the pad stays 10 square, and the ring and its shard stay 8 up on the outer side, so BayHalo is right at "
          "every stage. The growth is on the outer side and up, behind the worker from the court and the gate. All six "
          "bays at base level 3 at the same stage, a worker's size on each (a player's, 5.2; the tallest Voidkin is 7.4). "
          "Grey blocks in the base kit's swatches, with only the void's light lit, in the yard under the place's dusk, "
          "rendered in Blender; nothing is seen in Studio.")


def sheet(out, key, shots):
    gap, (w, h) = 16, look.SIZE
    cw, ch = round(w * 2 / 3), round(h * 2 / 3)
    keys = ["I", f"{key}II", f"{key}III"]
    union = tuple(f(shots.boxes[k][i] for k in keys) for i, f in enumerate((min, min, max, max)))
    union = (union[0] - 6, union[1] - 6, union[2] + 6, union[3] + 6)
    lines = [ln for n in (NOTES[key], SHARED + " Triangles, a bay, Stages I, II and III before the drawn edge's hull: " +
                          ", ".join(f"{shots.tris[k]:,}" for k in keys) + ".") for ln in textwrap.wrap(n, 230)]
    full = [shots.made[(k, "court")][max(int(union[1]), 0):int(union[3]), max(int(union[0]), 0):int(union[2])] for k in keys]
    full_h = max(px.shape[0] for px in full)
    small_h = 128 + 64 + 3 * gap + 40
    width = max(3 * cw + 4 * gap, sum(px.shape[1] for px in full) + 4 * gap)
    height = 48 + 3 * (ch + 34) + 34 + full_h + 34 + small_h + len(lines) * 19 + 24
    page = ui.Sheet(width, height, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 14, 20, f"Grow your Anime, the bays' stages: {key}, {STAGES[key]}", "#EDE6D6", bold=0.2)
    titles = ("Stage I, as it stands (machine levels 1 to 5)", "Stage II, levels 6 to 14", "Stage III, levels 15 and up")
    for row, (name, caption) in enumerate((("home", "from the game's start camera on the spawn, at a phone's 640 by 360"),
                                           ("gate", "from the gate, through it from the Strip"),
                                           ("row", "a player in the court turned to the left side's three bays"))):
        y = 48 + row * (ch + 34)
        for i, k in enumerate(keys):
            x = gap + i * (cw + gap)
            t.text(x, y, 14, f"{titles[i]}, {caption}" if i == 0 else titles[i], "#B4AC9C")
            rs.paste(page.px, rs.shrink(shots.made[(k, name)], 2 / 3), x, y + 22)
    y = 48 + 3 * (ch + 34)
    t.text(gap, y, 14, "Level 1's bay on the left, head-on from the court at its own size on a 960 by 540", "#B4AC9C")
    x = gap
    for px in full:
        rs.paste(page.px, px, x, y + 22)
        x += px.shape[1] + gap
    y += full_h + 34 + 8
    t.text(gap, y, 14, "The same, cut at one scale for the three: 64 and 128 px tall over the dark, and in black",
           "#B4AC9C")
    x = gap
    for i, k in enumerate(keys):
        x0 = x
        for px in (cut(shots.made[(k, "court")], union, 64), cut(shots.black[k], union, 64)):
            rs.paste(page.px, px, x, y + 26)
            x += px.shape[1] + 8
        x = x0
        for px in (cut(shots.made[(k, "court")], union, 128), cut(shots.black[k], union, 128)):
            rs.paste(page.px, px, x, y + 26 + 64 + gap)
            x += px.shape[1] + 8
        t.text(x0, y + 26 + 64 + 128 + 2 * gap, 13, titles[i].split(",")[0], "#EDE6D6")
        x += gap * 2
    y += small_h
    for i, ln in enumerate(lines):
        t.text(gap, y + i * 19, 14, ln, "#B4AC9C")
    for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
        rs.paste(page.px, layer, 0, 0)
    rs.save(page.px, out / f"bay_{key}.png")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    scene, yard, d = yard_without_bays(out, "fast" in args)
    shots = Shots(out, scene, yard, d)
    with Grey():
        meshes = {"I": bm.bay().mesh}
        for key, build in BUILD.items():
            meshes[f"{key}II"] = build(2)
            meshes[f"{key}III"] = build(3)
    for key, mesh in meshes.items():
        shots.take(key, mesh)
    ui.K = 1
    for key in STAGES:
        sheet(out, key, shots)
    print("triangles:", shots.tris)


if __name__ == "__main__":
    main()
