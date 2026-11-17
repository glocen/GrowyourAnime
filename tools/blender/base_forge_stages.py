"""AR36: the Forge's and the Stone Condenser's Stages II and III, two directions each in grey, for research's pick
(docs/asset-requests.md, AR36). Stage I is AR28's Press and Comb as they stand (base_forge.py), in colour beside them.

The Forge, A, the Gear Train: the head widens into a lintel carrying four meshing gears (II), stepped up at its ends to
carry two more over the outer pair, its horns clamped in bone (III). B, the Braced Press: a second pair of horns from
the deck's back corners braces the head from behind, the ram heavier on four rods (II); every horn clamped, the ram
heavier again with a bone rim, the head taller with a second line of the void's light (III).

The Stone Condenser, A, the Broad Comb: the comb a cup wider in every row, a second pair of horns hugging it from
behind (II); wider again, every horn clamped in bone (III). The core stays Stage I's (the content check, 19:24). B, the
Climbing Comb: cups climb the horns' outer sides, four on each (II), six (III). The Tall Comb, blocked by the check as
the dark-tower class, is replaced, not patched.

A throwaway: the chosen direction is rebuilt as kit pieces. Each machine's review renders in the yard at base level 3,
in two passes so the page fits in memory beside Studio:
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
import base_machines as bm  # noqa: E402
from base_mill import FACING, Mesh, at, prism, put, rod, turned  # noqa: E402
import lantern_row_kit as kit  # noqa: E402

GREY = {"steel": "concrete", "girder": "concrete", "abyss": "concrete", "yellow": "concrete", "copper": "concrete",
        "bone": "ceramic"}
DIRECTIONS = {"forge": {"A": "the Gear Train", "B": "the Braced Press"},
              "condenser": {"A": "the Broad Comb", "B": "the Climbing Comb"}}
HEAD_DEEP = 3.0           # B's head, deeper to hold the back horns' tips and four sleeves


class Swap:
    """While it's open, every swatch a shape asks for is drawn in its stand-in."""

    def __init__(self, table):
        self.table = table

    def __enter__(self):
        self.own = kit.sw_uv
        kit.sw_uv = lambda name, occ, t: self.own(self.table.get(name, name), occ, t)

    def __exit__(self, *_):
        kit.sw_uv = self.own


def clamps(m, points, radii, flat=(0.0, 1.0, 0.0), deep=0.9, n=3):
    """Bone clamps round a horn: one at the middle of each of its first `n` stretches, square to it."""
    across = Vector(flat).normalized()
    for k in range(min(n, len(points) - 1)):
        a, b = Vector(points[k]), Vector(points[k + 1])
        along = (b - a).normalized()
        side = across.cross(along).normalized()
        r = (radii[k] + radii[k + 1]) / 2
        rot = Matrix((side, across, along)).transposed()
        m.box((2 * r + 0.26, 2 * r * deep + 0.26, 0.32), (a + b) / 2, "bone", ink=True, rot=rot)


def gear(m, x, z, phase):
    """A ForgeGear on the head's face at (x, z), turned `phase` degrees about its axle."""
    put(m, bf.forge_gear(), at(x, bf.GEAR[1], z) @ Matrix.Rotation(math.radians(phase), 4, "Y"))


# --- the Forge ---------------------------------------------------------------------------------------------------------

ARCH = [(3.2, 0, 0.5), (4.7, 0, 4.4), (4.1, 0, 8.8), (1.7, 0, 11.3)]   # Stage I's horn, the right one
ARCH_R = [0.8, 0.72, 0.58, 0.42]


def gear_train(stage):
    """A: the lintel and its gears, beside Stage I's whole Press at rest."""
    m = bf.press("rest")
    low, top = bf.HEAD
    pitch = 2 * bf.GEAR[0]
    m.box((7.6, 2.4, top - low), (0, 0, (low + top) / 2), "abyss", ink=True)          # the lintel
    m.box((7.0, 0.1, 0.12), (0, 1.22, low + 0.1), "void")
    for sx in (-1, 1):
        m.box((0.9, 2.2, low - 9.0), (sx * 3.35, 0, (low + 9.0) / 2), "abyss", ink=True)   # its cheeks on the horns
    xs = [-1.5 * pitch, -0.5 * pitch, 0.5 * pitch, 1.5 * pitch]
    for k, x in enumerate(xs):
        gear(m, x, bf.GEAR[2], 22.5 * ((k + 1) % 2))         # each meshes the next; the middle two are Stage I's
    if stage == 3:
        for sx in (-1, 1):
            m.box((2.1, 2.4, 1.9), (sx * 2.75, 0, top + 0.95), "abyss", ink=True)  # the ends stepped up
            m.box((1.9, 0.1, 0.12), (sx * 2.75, 1.22, top + 0.1), "void")
            gear(m, sx * 1.5 * pitch, bf.GEAR[2] + pitch, 22.5 * (1 if sx < 0 else 0) + 22.5)   # over the outer one
            arch = [(sx * x, y, z) for x, y, z in ARCH]
            clamps(m, arch, ARCH_R)
    return m


def ram(r, high, rim):
    """B's heavier ram, its origin its underside's middle: four rods, a band, a disc of light, a bone rim at III."""
    m = Mesh()
    put(m, turned([(r, high), (r, 0.0)], 8, "abyss"), at(0, 0, 0))
    put(m, turned([(r + 0.08, 0.3), (r + 0.08, 0.0)], 8, "void"), at(0, 0, high - 0.45))
    bf.disc(m, (0, 0, 0), r - 0.45, 0.08, "void", axis=(0, 0, 1), sides=8, ink=False)
    if rim:
        put(m, turned([(r + 0.14, 0.3), (r + 0.14, 0.0)], 8, "bone"), at(0, 0, 0.0))
    for sx in (-1, 1):
        for sy in (-1, 1):
            x, y = sx * bf.RODS[0], sy * 0.55
            m.box((0.6, 0.6, 0.2), (x, y, high + 0.1), "bone", ink=True)
            rod(m, (x, y, high + 0.2), (x, y, high + bf.RODS[1]), bf.RODS[2], "steel")
            put(m, turned([(0.28, 0.35), (0.28, 0.0)], 8, "bone"), at(x, y, high + bf.RODS[1] - 0.35))
    return m


BACK = [(3.2, -3.2, 0.5), (3.7, -3.7, 5.0), (2.7, -2.7, 9.2), (1.3, -1.3, 11.6)]   # the back horn, the right one
BACK_R = [0.62, 0.52, 0.4, 0.3]


def braced(stage):
    """B: the back horns bracing the head, the heavier ram; at III every horn clamped and the head taller."""
    m = bf.forge()
    low, top = bf.HEAD
    m.box((3.6, HEAD_DEEP, top - low), (0, 0, (low + top) / 2), "abyss", ink=True)
    q = math.sqrt(0.5)
    for sx in (-1, 1):
        back = [(sx * x, y, z) for x, y, z in BACK]
        flat = (q, sx * q, 0.0)
        bm.horn(m, back, BACK_R, "abyss", flat=flat, deep=0.8)
        bm.vein(m, back, BACK_R, (0, 0, 6.0))
        for sy in (-1, 1):                                                           # the four sleeves
            rod(m, (sx * bf.RODS[0], sy * 0.55, low + 0.05), (sx * bf.RODS[0], sy * 0.55, bf.SLEEVE), 0.34, "girder")
        if stage == 3:
            clamps(m, [(sx * x, y, z) for x, y, z in ARCH], ARCH_R)
            clamps(m, back, BACK_R, flat=flat, deep=0.8)
    if stage == 3:
        m.box((3.6, HEAD_DEEP, 0.9), (0, 0, top + 0.45), "abyss", ink=True)          # the head taller
        m.box((3.4, 0.1, 0.12), (0, HEAD_DEEP / 2 + 0.02, top + 0.72), "void")       # its second line, full width,
                                                                                      # over the gears' teeth
    put(m, ram(2.6, 1.9, True) if stage == 3 else ram(2.3, 1.7, False), at(0, 0, bf.POSES["rest"]))
    for sx in (-1, 1):
        put(m, bf.forge_gear(), bf.gear_turn(sx, 0.0) @ Matrix.Translation((0, HEAD_DEEP / 2 - 1.2, 0)))
    return m


# --- the Stone Condenser -----------------------------------------------------------------------------------------------

def rows(extra):
    return tuple(n + extra for n in bf.ROWS)


def cups_of(extra):
    """The comb's cups a row `extra` wider, in their filling order: by rows from the bottom up, each from its middle."""
    r, spacing = bf.CELL
    dx, dz = math.sqrt(3) * r * spacing, 1.5 * r * spacing
    out = []
    for row, n in enumerate(rows(extra)):
        z = bf.PANEL[0] + (row - 3) * dz
        xs = [(i - (n - 1) / 2) * dx for i in range(n)]
        out += [(round(x, 3) + 0.0, round(z, 3)) for x, z in sorted(((x, z) for x in xs), key=lambda p: (abs(round(p[0], 3)), -p[0]))]
    return out


def cup(m, x, z, y=bf.FACE):
    """One six-sided cup on a face at `y`, as the comb's: a dark plug and its rim."""
    r = bf.CELL[0]
    ri, ro, lip = 0.78 * r, 0.98 * r, 0.22
    uv = [kit.sw_uv("girder", 0.0, 0.6)] * 4
    bf.plug(m, x, y + 0.02, z, ri + 0.03, "ink")
    inner, outer = bf.hexagon(x, y, z, ri), bf.hexagon(x, y, z, ro)
    front_in, front_out = bf.hexagon(x, y + lip, z, ri), bf.hexagon(x, y + lip, z, ro)
    axis = Vector((x, y + lip / 2, z))
    for k in range(6):
        j = (k + 1) % 6
        m.out([front_in[k], front_out[k], front_out[j], front_in[j]], uv, Vector((x, y - 1.0, z)))
        m.out([outer[k], outer[j], front_out[j], front_out[k]], uv, axis)
        wall = [inner[k], inner[j], front_in[j], front_in[k]]
        m.out(wall, uv, axis + (sum(wall, Vector()) / 4 - axis) * 3.0)


def horns(spread):
    """The front horns, the right one, `spread` wider at their middle (Stage I's at 0)."""
    rp, mid = bf.panel_radius(), bf.PANEL[0]
    return [(2.7 + spread / 2, -0.4, 0.5), (rp + 0.8 + spread, -0.4, mid), (3.0 + spread, -0.4, 7.7), (1.65, -0.4, 9.8)]


HORN_R = [0.6, 0.46, 0.38, 0.07]


def climbing(stage):
    """The places of B's cups up the horns' outer sides, the right one's: across and up."""
    pts, out = horns(0.0), []
    for k in range(4 if stage == 2 else 6):
        z = 1.6 + 1.06 * k
        seg = 0 if z <= pts[1][2] else 1
        (x0, _, z0), (x1, _, z1) = pts[seg], pts[seg + 1]
        t = (z - z0) / (z1 - z0)
        x = x0 + (x1 - x0) * t
        w = HORN_R[seg] + (HORN_R[seg + 1] - HORN_R[seg]) * t
        out.append((round(x + w + 0.55, 3), round(z, 3)))
    return out


def comb_stage(direction, stage, fill=0.5):
    """A Condenser at Stage II or III, a direction's, with a stone in the first `fill` of its cups."""
    extra = (stage - 1) if direction == "A" else 0
    r, spacing = bf.CELL
    spread = extra * math.sqrt(3) * r * spacing / 2
    m = Mesh()
    bf.deck(m)
    rp, mid = bf.panel_radius(), bf.PANEL[0]
    m.box((4.0 + 2 * spread, 1.4, 0.6), (0, -0.4, 0.8), "girder", ink=True)
    rim = []
    for k in range(6):                                     # the panel, stretched across by its extra cups
        a = math.radians(60 * k)
        rim.append(Vector((rp * math.cos(a) + math.copysign(spread, math.cos(a)) * (abs(math.cos(a)) > 0.1),
                           rp * math.sin(a), 0.0)))
    flat = Mesh()
    prism(flat, rim, 1.0, "abyss", Vector((0, 0, 0)))
    put(m, flat, at(0, bf.FACE - 0.5, mid) @ FACING)
    places = cups_of(extra)
    side = [(s * x, z) for x, z in (climbing(stage) if direction == "B" else []) for s in (1, -1)]
    for x, z in places:
        cup(m, x, z)
    for x, z in side:                                      # B's cups, each on a plate set on its horn
        plate = Mesh()
        prism(plate, [Vector((0.66 * math.cos(math.radians(90 + 60 * k)), 0.66 * math.sin(math.radians(90 + 60 * k)), 0))
                      for k in range(6)], 0.6, "abyss", Vector((0, 0, 0)))
        put(m, plate, at(x, bf.FACE - 0.3, z) @ FACING)
        cup(m, x, z)
    for sx in (-1, 1):
        front = [(sx * x, y, z) for x, y, z in horns(spread)]
        m.box((1.6, 1.8, 0.4), (sx * (2.7 + spread / 2), -0.4, 0.7), "girder", ink=True)
        bm.horn(m, front, HORN_R, "abyss", deep=0.9)
        bm.vein(m, front, HORN_R, (0, -0.4, mid))
        if direction == "A":
            foot = 3.3 + spread / 3                        # on the deck at every stage
            back = [(sx * foot, -2.0, 0.5), (sx * (rp + 1.3 + spread), -2.0, mid),   # ends under the front pair's
                    (sx * (3.3 + spread), -2.0, 7.0), (sx * (2.3 + spread / 2), -2.0, 7.9)]   # shoulder, clear of the core
            back_r = [0.5, 0.4, 0.32, 0.14]
            m.box((1.3, 1.4, 0.4), (sx * foot, -2.0, 0.7), "girder", ink=True)
            bm.horn(m, back, back_r, "abyss", deep=0.8)
            if stage == 3:
                clamps(m, front, HORN_R)
                clamps(m, back, back_r, deep=0.8)
    bm.shard(m, bf.CORE, 0.45, 1.6, "void")
    cx, cy, cz = bf.CORE
    bf.motes(m, [(cx + d * math.cos(a), cy + 0.3, cz + d * math.sin(a))
                 for a, d in ((0.35, 2.1), (1.25, 2.25), (1.95, 2.0), (2.85, 2.2), (-0.5, 1.9), (3.7, 1.95))], 0.18)
    put(m, bf.condenser_core(), at(*bf.CORE))
    m.box((1.1, 0.9, 0.8), (1.2, -3.6, 0.9), "girder", ink=True)
    bf.cable(m, [(1.2, -4.9, 0.25), (1.2, -4.3, 0.25), (1.2, -3.6, 0.9)], r=0.24)
    bf.cradle(m, -3.0, 3.2)
    order = sorted(places + side, key=lambda p: (round(p[1], 2), abs(p[0]), -p[0]))
    for x, z in order[:round(len(order) * fill)]:
        put(m, bf.condenser_stone(), at(x, bf.FACE, z))
    return m, len(order)


# --- each machine's stages ---------------------------------------------------------------------------------------------

def variants(machine):
    """Stage I in colour, then each direction's II and III in grey, by their keys."""
    if machine == "forge":
        made = {"I": bf.press("rest")}
        for key, body in (("A", gear_train), ("B", braced)):
            for stage in (2, 3):
                with Swap(GREY):
                    made[f"{key}{'I' * stage}"] = body(stage)
        return made, {}
    made, counts = {"I": bf.comb(0.5)[0]}, {"I": len(bf.cups())}
    for key in ("A", "B"):
        for stage in (2, 3):
            with Swap(GREY):
                made[f"{key}{'I' * stage}"], counts[f"{key}{'I' * stage}"] = comb_stage(key, stage)
    return made, counts


# --- the review: each machine in the yard --------------------------------------------------------------------------------

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
             "high": ((x + inner * 10.0, -inward + 10.0, mid[2] + 13.0), mid)}
    w, h = look.SIZE
    boxes, tris = {}, {}
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
        out_, steps = [], 80
        for o, (lo, hi) in standing:
            if hi.z < 1.2:
                continue
            for i in range(steps + 1):
                p = eye.lerp(target, i / steps)
                if Vector((p.x - target.x, p.y - target.y)).length < near:
                    break
                if all(lo[k] - 0.5 <= p[k] <= hi[k] + 0.5 for k in range(3)):
                    out_.append(o)
                    break
        return out_

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

    made, counts = variants(machine)
    for key, mesh in made.items():
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
            if key == "I" and hidden:
                print(view, "clear of", [o.name for o in hidden])
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
    ("forge", "A"): "The Gear Train: its growth is the mechanism. At Stage II the head widens into a lintel 7.6 across "
                    "on the horns' shoulders, carrying four gears in a row, each meshing the next, turning with the ram "
                    "as Stage I's two do (ForgeGear, more places). At Stage III the lintel steps up at its ends to carry "
                    "two more, one over each outer gear and meshing only it, six in all, and each horn takes three bone "
                    "clamps. The seat, the plate and the ram stay Stage I's.",
    ("forge", "B"): "The Braced Press: its growth is the frame and the ram. At Stage II a second pair of horns rises from "
                    "the deck's back corners, thinner than the first and on a straighter line, and is buried in the "
                    "head, bracing it from behind; the ram is heavier, 4.6 across on four rods. At Stage III every horn "
                    "takes three bone clamps, the ram is 5.2 across with a plain bone rim, and the head is taller with a "
                    "second line of the void's light its full width. Nothing grows in front of the seat.",
    ("condenser", "A"): "The Broad Comb: its growth goes out. At Stage II the comb is a cup wider in every row, 44 "
                        "cups, and a second pair of horns hugs it from behind, ending under the front horns' shoulders. At Stage III it "
                        "is wider again, 51 cups, and every horn takes three bone clamps. The core stays Stage I's.",
    ("condenser", "B"): "The Climbing Comb: its growth climbs the horns. At Stage II four cups stand on plates up each "
                        "horn's outer side, 45 in all; at Stage III six on each, 49. The comb and the core stay Stage "
                        "I's; the cups fill from the lowest up, the climbing ones with their row's height.",
}


def sheet(out, machine):
    """Each direction's sheet, Stage I beside its II and III, from the shots on disk, in a Blender of its own."""
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
    for direction, called in DIRECTIONS[machine].items():
        keys = ("I", f"{direction}II", f"{direction}III")

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
        titles = ("Stage I, as it stands (AR28)", "Stage II, in grey", "Stage III, in grey")
        cups = f" Cups: Stage I {counts['I']}, II {counts[keys[1]]}, III {counts[keys[2]]}, half of them holding a stone." \
            if counts else ""
        notes = [NOTES[(machine, direction)],
                 "Stage I in the base kit's colours, II and III in grey, in the yard at base level 3 under the place's "
                 "dusk, rendered in Blender; nothing is seen in Studio. Triangles, a stage whole before the drawn edge's "
                 "hull: " + ", ".join(f"{t} {tris[k]:,}" for t, k in zip(("I", "II", "III"), keys)) + "." + cups]
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
        ui.K = 1
        page = ui.Sheet(width, height, "#14151C")
        t = page.tile(0, 0, page.w, page.h)
        t.text(gap, 14, 20, f"Grow your Anime, {title}'s stages: {direction}, {called} (AR36, grey block)", "#EDE6D6",
               bold=0.2)
        y = 48
        for view, caption in (("court", "a player at the court's back turned to it, at a phone's 640 by 360"),
                              ("way", "a player walking up to it from the main line, turned to it")):
            for i, k in enumerate(keys):
                x0 = gap + i * (cw + gap)
                t.text(x0, y, 14, f"{titles[i]}: {caption}" if i == 0 else titles[i], "#B4AC9C")
                rs.paste(page.px, rs.shrink(shot(k, view), 2 / 3), x0, y + 22)
            y += ch + 34
        for view in FULL_VIEWS:
            t.text(gap, y, 14, f"{said[view]}, at its own size on a 960 by 540", "#B4AC9C")
            x0 = gap
            for px in fulls[view]:
                rs.paste(page.px, px, x0, y + 22)
                x0 += px.shape[1] + gap
            y += max(px.shape[0] for px in fulls[view]) + 42
        for view in CUT_VIEWS:
            t.text(gap, y, 14, f"{said[view]}: cut at one scale for the three, 64 and 128 px tall over the dark, and "
                   f"in black", "#B4AC9C")
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
                t.text(left, y + 26 + 64 + 128 + 2 * gap - 6, 13, titles[i].split(",")[0], "#EDE6D6")
                x0 += 2 * gap
            y += small
        y += 14
        for i, ln in enumerate(lines):
            t.text(gap, y + i * 19, 14, ln, "#B4AC9C")
        for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
            rs.paste(page.px, layer, 0, 0)
        rs.save(page.px, out / f"{machine}_{direction}.png")
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
