"""AR32: the Void Breaker's Stages II and III, the Great Jaws, as base kit pieces (docs/asset-requests.md, AR32).

The Breaker takes the stage of its machine level: Stage I from level 1, II from 6, III from 15 (Config.Base, Stages).
The jaws grow with the line. They root at its two ends and arch over every chamber to a gap over its middle, where the
crystal floats. Two lower jaws meet under them in a bone clamp, and each chamber's fang hangs from them. A hinge gear
stands at each jaw's root, on both long faces. At Stage III the jaws reach higher, each grows a tall barb from its
elbow, and two claws rise round the crystal past its top, so the top line changes from the spawn too (research's
must-fix of 17:01).

The chambers keep their places: 1 and 2 where they stand, 3 and 4 on along the line outward, 7 studs apart. Chamber 3
arrives with Stage II and opens at machine level 8; chamber 4 arrives with Stage III and opens at 20
(Config.Base, BreakerChambers). Until its chamber opens, a seat is shut by a dark lid. The body grows a section a
chamber and stays 5 high, so a chamber's foot and its shard's room are where they are today. From Stage II the waiting
line's three cradles stand at the body's front foot.

The pieces (base_kit.py takes PIECES), each in the Breaker's own frame, stood at the Breaker's place:
  Breaker2, Breaker3   each stage's still body, jaws and crystal, in place of Breaker
  BreakerHinge         a jaw's hinge: a gear on each long face, on one axle through the jaw's root; it turns
  BreakerLid           a seat whose chamber hasn't opened: a lid of void stone, unlit
BreakerChamber and BreakerWaiting are Stage I's, stood again. The swap's table is tables(): plan.json's
machines.breakerStages.

The content check's conditions (2026-11-17) hold: the crystal is a faceted lozenge between a mirrored pair, never a star
or rays; fangs, jaws, barbs, claws and clamps are clean stone or bone, never lit at a tip; every vein stops at least a
stud short of a tip; nothing reads as a throat, gums or vertebrae; no stage is a tall tapering tower.

The review, each stage from the spawn's start camera and from a player inside the gate, cut small and in black:
blender.exe -b --factory-startup --python-exit-code 1 --python tools/blender/base_breaker.py -- <abs out_dir> [fast]
"""

import math
import sys
import textwrap
from pathlib import Path

from mathutils import Matrix

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_machines as bm  # noqa: E402
from base_mill import FACING, Mesh, at, disc, put, toothed  # noqa: E402
from lantern_row_kit import Piece  # noqa: E402

STEP, FIRST = 7.0, -3.5               # the chambers along the line: their step, and chamber 1's place
FOOT = bm.BODY[2]                     # the body's top, where a chamber stands
FANG_TIP = bm.GAP[1] + 0.12           # a fang's point, over the shard's room
BACKWARD = Matrix.Rotation(math.pi / 2, 4, "X")   # a part built about Z, turned so its Z looks away from the gate (-Y)
HINGE = dict(r=1.0, teeth=10, face=1.15, up=6.3, inset=0.7)   # its gear; out to each face; up; in from the line's end

# Each stage's jaws. `reach`: the upper jaw from its root to its tip, (out from the middle, up), the root's `out` from
# the line's half length; `low`: where the lower jaws meet; `crystal`: its middle up, its radius, its height.
SHAPE = {
    2: dict(chambers=3, reach=[(-0.4, FOOT), (0.9, 9.6), (-0.5, 13.4), (6.2, 15.1), (2.4, 15.4)],
            widths=[1.0, 0.95, 0.8, 0.5, 0.06], low=11.2, crystal=(14.4, 1.3, 5.0)),
    3: dict(chambers=4, reach=[(-0.4, FOOT), (1.0, 10.4), (-0.4, 15.2), (8.8, 17.2), (2.6, 17.6)],
            widths=[1.2, 1.1, 0.95, 0.6, 0.07], low=12.4, crystal=(16.4, 1.5, 6.0)),
}
# Stage III's must-fix: what it adds over the jaws, high enough to change the top line from the spawn, and no higher
# than the start camera's frame allows (its top is about 20 up over the Breaker's middle). The barb rises from each
# jaw's elbow, out and up past the jaws' crest (its places from the elbow); the claws rise from the lower jaws' clamp
# round the crystal and close over its top (their places from the middle).
BARB = [(-0.3, 0.0), (1.5, 3.6), (1.8, 6.6), (1.1, 8.8)], [0.8, 0.6, 0.38, 0.05]
CLAW = [(0.7, 12.9), (2.3, 15.3), (1.95, 17.9), (0.95, 20.0)], [0.4, 0.32, 0.2, 0.05]


def chambers(n):
    return [FIRST + STEP * k for k in range(n)]


def span(n):
    """The body's two ends along the line."""
    return -7.0, FIRST + STEP * (n - 1) + 3.5


def middle(stage):
    """The line's middle and its half length at a stage."""
    x0, x1 = span(SHAPE[stage]["chambers"])
    return (x0 + x1) / 2, (x1 - x0) / 2


def lamp(stage):
    """The crystal's middle: where the builder's BreakerLamp stands at the stage."""
    if stage == 1:
        return 0.0, 0.0, 10.2
    return middle(stage)[0], 0.0, SHAPE[stage]["crystal"][0]


def hinges(stage):
    """Each hinge's axle, left then right along the line."""
    xc, half = middle(stage)
    return [(xc + s * (half - HINGE["inset"]), 0.0, HINGE["up"]) for s in (-1, 1)]


def waiting(stage):
    """The waiting line's three places: along the line's end at Stage I, at the body's front foot after it."""
    if stage == 1:
        return [(9.0 + 3.0 * k, 0.0) for k in range(3)]
    xc = middle(stage)[0]
    return [(xc + 3.0 * (k - 1), 5.1) for k in range(3)]


def under(d, half, low):
    """The lower jaw's height `d` out from the middle: an arch under the upper jaws, `low` where the two meet."""
    return low - 1.6 * (d / half) ** 2


# --- the shapes -------------------------------------------------------------------------------------------------------

def body(m, n):
    """Stage I's body grown a section a chamber: the same plinth, block, cap and foot line, a window of the void under
    each chamber on both faces, and the veins running between them."""
    x0, x1 = span(n)
    length, xc = x1 - x0, (x0 + x1) / 2
    _, deep, high = bm.BODY
    m.box((length + 0.6, deep + 0.6, 0.6), (xc, 0, 0.3), "girder", ink=True)
    m.box((length + 0.2, deep + 0.2, 0.16), (xc, 0, 0.74), "cyan")
    m.box((length, deep, 3.4), (xc, 0, 2.8), "abyss", ink=True)
    m.box((length + 0.4, deep + 0.4, 0.5), (xc, 0, high - 0.25), "bone", ink=True)
    for sy in (-1, 1):
        y = sy * (deep / 2 + 0.03)
        for x in chambers(n):
            m.box((2.6, 0.16, 2.4), (x, y, 2.9), "dark")
            m.box((0.34, 0.2, 1.9), (x, y + sy * 0.02, 2.9), "cyan")
        for a, b in zip(chambers(n)[:-1], chambers(n)[1:]):
            m.box((STEP - 2.8, 0.14, 0.2), ((a + b) / 2, y, 4.1), "void")
        for end, s in ((x0, 1), (x1, -1)):
            m.box((1.6, 0.14, 0.2), (end + s * 1.3, y, 4.1), "void")
            m.box((0.2, 0.14, 1.9), (end + s * 0.6, y, 3.25), "void")
    for end, s in ((x0, -1), (x1, 1)):                       # the rail's coupling at each end
        m.box((0.5, 2.2, 1.8), (end + s * 0.2, 0, 2.0), "girder", ink=True)
        m.box((0.14, 1.4, 0.24), (end + s * 0.47, 0, 2.0), "cyan")


def fang(m, x, top, clamp=True):
    """A chamber's fang from `top` down to its shard, unlit, a bone clamp where it hangs."""
    bm.horn(m, [(x, 0, top), (x, 0, FANG_TIP)], [0.5, 0.05], "abyss")
    if clamp:
        m.box((0.6, 1.25, 0.9), (x, 0, top + 0.1), "bone", ink=True)


def still(stage):
    """A stage's still body: the grown body, the jaws over it, the fangs, and the crystal in the jaws' gap."""
    m = Mesh()
    shape = SHAPE[stage]
    body(m, shape["chambers"])
    xc, half = middle(stage)
    reach = [(half + d if i < 3 else d, z) for i, (d, z) in enumerate(shape["reach"])]
    widths, low = shape["widths"], shape["low"]
    for s in (-1, 1):
        upper = [(xc + s * d, 0, z) for d, z in reach]
        m.box((2.2, 2.4, 0.4), (upper[0][0], 0, FOOT + 0.2), "girder", ink=True)
        bm.horn(m, upper, widths, "abyss", deep=0.8)
        bm.vein(m, upper[:4] + [(xc + s * (reach[4][0] + 1.4), 0, reach[4][1] - 0.4)], widths[:4] + [0.3], (xc, 0, 9.0))
        lower = [(xc + s * (half + 0.2), 0, 8.4)] + [(xc + s * d, 0, under(d, half, low)) for d in (0.75 * half, 0.4 * half, 0.5)]
        bm.horn(m, lower, [0.75, 0.62, 0.45, 0.3], "abyss", deep=0.9)   # the lower jaw, arched under the upper
        if stage == 3:
            ex, ez = reach[1]
            bm.horn(m, [(xc + s * (ex + dx), 0, ez + dz) for dx, dz in BARB[0]], BARB[1], "abyss", deep=0.8)
            bm.horn(m, [(xc + s * dx, 0, z) for dx, z in CLAW[0]], CLAW[1], "abyss", deep=0.8)
    m.box((1.6, 1.4, 1.1), (xc, 0, low + 0.1), "bone", ink=True)  # where the lower jaws meet
    for x in chambers(shape["chambers"]):
        fang(m, x, under(abs(x - xc), half, low) - 0.1, clamp=abs(x - xc) > 0.6)
    up, r, high = shape["crystal"]
    bm.shard(m, (xc, 0, up), r, high, "cyan")
    return m


def hinge():
    """A jaw's hinge: a gear of void stone with a solid web and a bone hub on each long face, on one axle."""
    m = Mesh()
    for y, turn in ((HINGE["face"], FACING), (-HINGE["face"], BACKWARD)):
        g = toothed(HINGE["r"], HINGE["teeth"], 0.3, 0.32)
        disc(g, (0, 0, 0.2), 0.34, 0.2, "bone", axis=(0, 0, 1), sides=8)
        put(m, g, at(0, y, 0) @ turn)
    return m


def lid():
    """A seat whose chamber hasn't opened: the chamber's foot, shut by a lid of void stone held by two bone bars."""
    m = Mesh()
    side = bm.CHAMBERS[2]
    m.box((side + 0.2, side + 0.2, 0.3), (0, 0, 0.15), "abyss", ink=True)
    m.box((side - 0.6, side - 0.6, 0.35), (0, 0, 0.47), "abyss", ink=True)
    m.box((side - 1.4, side - 1.4, 0.06), (0, 0, 0.67), "dark")
    for s in (-1, 1):
        m.box((0.5, side + 0.1, 0.24), (s * 1.05, 0, 0.72), "bone", ink=True)
    return m


# --- the kit's pieces and the swap's table ------------------------------------------------------------------------------

def breaker_stage(stage):
    def make():
        n = SHAPE[stage]["chambers"]
        x0, x1 = span(n)
        xc = (x0 + x1) / 2
        grown = ("its jaws arched over three chambers to 15.4" if stage == 2 else
                 "its jaws arched over four chambers to 17.6, a barb from each jaw's elbow to 19.2, and two claws round "
                 "the crystal to 20")
        return Piece(f"Breaker{stage}", still(stage),
                     solid=f"a box {x1 - x0:g} along the line, 6 deep and 5 high, its middle {xc:g} across; the jaws "
                           f"stand on its top",
                     note=f"Stage {'II' if stage == 2 else 'III'}'s still body, in place of Breaker at the same place: "
                          f"the body grown to {n} chambers ({x1 - x0:g} long, from {x0:g} to {x1:g} across), {grown}. "
                          f"The crystal is the Breaker's lamp: BreakerLamp stands at its middle, {lamp(stage)[2]:g} up "
                          f"and {xc:g} across. The chambers, the hinges, the lids and the waiting line stand by "
                          f"machines.breakerStages")
    return make


def breaker_hinge():
    r, face, up = HINGE["r"], HINGE["face"], HINGE["up"]
    return Piece("BreakerHinge", hinge(),
                 note=f"Stages II and III: a jaw's hinge, a gear ({HINGE['teeth']} teeth, {2 * r:g} across) on each "
                      f"long face, {face:g} out, on one axle through the jaw's root. Its origin on the axle's middle, "
                      f"{up:g} up; its axle along the piece's Y (Roblox's Z). It turns while chambers break, "
                      f"CFrame.Angles(0, 0, angle * sign) with the sign the table gives, so the two turn mirrored as "
                      f"the jaws are. Look only")


def breaker_lid():
    return Piece("BreakerLid", lid(),
                 note="a seat whose chamber hasn't opened: stood in place of BreakerChamber at its place, on the body's "
                      "top, until the Breaker has that chamber. Unlit. Look only")


def stages():
    """The swap's table: each stage's pieces at the Breaker's place (across, toward the gate, up), how each moves,
    and where its lamp stands."""
    table = {}
    for stage in (1, 2, 3):
        n = 2 if stage == 1 else SHAPE[stage]["chambers"]
        rows = [dict(piece="Breaker" if stage == 1 else f"Breaker{stage}", at=[0.0, 0.0, 0.0], moves="still")]
        for k, x in enumerate(chambers(n)):
            row = dict(piece="BreakerChamber", at=[x, 0.0, FOOT], moves="chamber", chamber=k + 1)
            if k >= 2:
                row["shut"] = "BreakerLid"
            rows.append(row)
        if stage > 1:
            for sign, (x, y, z) in zip((1, -1), hinges(stage)):
                rows.append(dict(piece="BreakerHinge", at=[round(x, 3), y, z], moves="turns", sign=sign))
        for k, (x, y) in enumerate(waiting(stage)):
            rows.append(dict(piece="BreakerWaiting", at=[x, y, 0.0], moves="waiting", place=k + 1))
        table[str(stage)] = dict(pieces=rows, lamp=[round(v, 3) for v in lamp(stage)])
    return table


def tables():
    return dict(breakerStages=dict(
        note="AR32: the Void Breaker's three stages, the Great Jaws, the swap's table. The Breaker takes the stage of "
             "its machine level (Config.Base, Stages: 1, 6, 15). Every place is in the Breaker's own frame, turned "
             "with it: `across` along the line (chamber 1 nearest the plot's middle, the line going on outward), "
             "`along` toward the gate, `up` from its floor. A stage's pieces replace the one before's. `moves`: "
             "still; chamber, the chamber of that number, lit by its state as today; while the Breaker hasn't that "
             "chamber yet (Config.Base, BreakerChambers: 3 from level 8, 4 from 20), `shut` stands in its place; "
             "turns, about the piece's own axle while any chamber breaks, CFrame.Angles(0, 0, angle * sign); "
             "waiting, the waiting line's place of that number. `lamp`: where BreakerLamp stands, the crystal's middle.",
        stages=stages()))


PIECES = {"Breaker2": breaker_stage(2), "Breaker3": breaker_stage(3), "BreakerHinge": breaker_hinge,
          "BreakerLid": breaker_lid}


# --- the review: each stage in the yard, from the spawn's start camera and the gate's view -----------------------------

def stood(stage, shut=()):
    """A stage whole, every piece at its table's place, the chambers in `shut` lidded: for the review."""
    m = Mesh()
    made = {"Breaker": bm.breaker().mesh, "BreakerChamber": bm.breaker_chamber().mesh,
            "BreakerWaiting": bm.breaker_waiting().mesh, "BreakerHinge": hinge(), "BreakerLid": lid()}
    if stage > 1:
        made[f"Breaker{stage}"] = still(stage)
    for row in stages()[str(stage)]["pieces"]:
        name = row["shut"] if row.get("chamber") in shut else row["piece"]
        put(m, made[name], at(*row["at"]))
    return m


def review(out, fast):
    import numpy as np
    import bpy
    from bpy_extras.object_utils import world_to_camera_view
    from mathutils import Vector
    import base_kit as base
    import base_plan as plan
    import blcommon as bl
    import lantern_row_look as look
    import rook_sheet as rs
    import ui_sheet as ui

    BX, BI = plan.BREAKER
    gate_player = (BX + 4.0, -(BI - 12.0))   # a player inside the gate, before the Breaker's middle

    made = plan.machines                      # the yard as it stands, its Breaker taken out
    plan.machines = lambda level=1: [row for row in made(level) if not row[0].startswith("Breaker")]
    d = look.DIRECTIONS["M"]
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1], azimuth=d.get("glow_az", 0.0),
                    away=look.srgb(d["fog_away"]) if "fog_away" in d else None)
    scene = bl.reset_scene()
    base.write_pictures(out / "maps")
    yard = plan.Yard(scene, 1, out / "maps")
    yard.plot(0.0, 1)
    yard.plot(plan.STRIP, -1)
    yard.kit.block("Strip", (3 * plan.PLOT, plan.STRIP, 0.4), (0, plan.STRIP / 2, -0.22), yard.stone)
    yard.kit.block("Ground", (5 * plan.PLOT, 4 * plan.PLOT, 0.4), (0, plan.STRIP / 2, -0.3), yard.flat["ground"])
    yard.person((base.SPAWN[0], -base.SPAWN[1]))
    yard.person(gate_player, "Near")
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

    pitch, up = math.radians(20.0), Vector((0.0, 0.0, 1.0))
    spawn = Vector((base.SPAWN[0], -base.SPAWN[1], 3.0 + look.FOCUS))
    flat = Vector((BX - spawn.x, -BI - spawn.y, 0.0)).normalized()
    near = Vector((*gate_player, 3.0 + look.FOCUS))
    views = {"start": (tuple(spawn - flat * math.cos(pitch) * look.ZOOM + up * math.sin(pitch) * look.ZOOM), tuple(spawn)),
             "gate": (tuple(near + Vector((0, 1, 0)) * math.cos(pitch) * look.ZOOM + up * math.sin(pitch) * look.ZOOM),
                      (BX + 4.0, -BI, 9.0))}
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

    def take(key, stage, names, shut=()):
        mesh = stood(stage, shut)
        tris[key] = mesh.whole().tris()
        data = mesh.whole().to_object(f"Breaker{key}", yard.stock.mats["Kit"])
        obj = bpy.data.objects.new(f"Breaker{key}", data)
        obj.location = (BX, -BI, 0.0)
        scene.collection.objects.link(obj)
        n = 2 if stage == 1 else SHAPE[stage]["chambers"]
        shards = [yard.kit.block(f"Shard{key}{k}", (1.0, 1.0, 1.7), (BX + x, -BI, sum(bm.GAP) / 2), yard.flat["chamber"])
                  for k, x in enumerate(chambers(n)) if k >= 2 and k + 1 not in shut]
        light = bpy.data.objects.get("BreakerLampA")        # the Breaker's lamp, on this stage's crystal
        if light is not None:
            lx, ly, lz = lamp(stage)
            light.location = (BX + lx, -BI + ly, lz)
        bpy.context.view_layer.update()
        for name in names:
            eye, target = views[name]
            scene.camera = plan.camera(scene, f"Cam{key}{name}", eye, target)
            path = out / f"breaker_{key}_{name}.png"
            px = look.finish(look.render_linear(scene, path.with_suffix(".exr")), d)
            path.with_suffix(".exr").unlink(missing_ok=True)
            shots[(key, name)] = px
            pts = [world_to_camera_view(scene, scene.camera, obj.matrix_world @ v.co) for v in obj.data.vertices]
            boxes[(key, name)] = (min(p.x for p in pts) * w, min((1 - p.y) for p in pts) * h,
                                  max(p.x for p in pts) * w, max((1 - p.y) for p in pts) * h)
            black[(key, name)] = silhouette(obj, out / f"_black_{key}_{name}.png")
        for shard in shards:
            bpy.data.objects.remove(shard)
        bpy.data.objects.remove(obj)
        bpy.data.meshes.remove(data)

    for key, stage in (("I", 1), ("II", 2), ("III", 3)):
        take(key, stage, ("start", "gate"))
    take("IIshut", 2, ("gate",), shut=(3,))

    def cut(px, box, scale):
        x0, y0, x1, y1 = (int(v) for v in box)
        return rs.shrink(px[max(y0, 0):y1, max(x0, 0):x1], scale)

    def union(name):
        b = [boxes[(k, name)] for k in ("I", "II", "III")]
        return (min(v[0] for v in b) - 6, min(v[1] for v in b) - 6, max(v[2] for v in b) + 6, max(v[3] for v in b) + 6)

    keys = ("I", "II", "III")
    titles = ("Stage I, machine levels 1 to 5, as it stands", "Stage II, levels 6 to 14", "Stage III, levels 15 and up")
    notes = [
        "The jaws grow with the line. They root at its two ends and arch over every chamber to a gap over its middle, "
        "where the crystal floats. Two lower jaws meet under them in a bone clamp, and each chamber's fang hangs from "
        "them. A hinge gear stands at each jaw's root, on both faces, and turns while chambers break. At Stage III the "
        "jaws reach 17.6, a barb rises from each jaw's elbow to 19.2, and two claws rise round the crystal to 20, so "
        "the top line changes from the spawn too (research's must-fix).",
        "Chambers 1 and 2 stand where they stand, and 3 and 4 go on along the line outward, 7 studs apart: chamber 3 "
        "arrives with Stage II and opens at level 8, chamber 4 with Stage III and opens at 20. Until then a dark lid "
        "shuts its seat. The waiting line's three cradles stand at the body's front foot. In the base kit's colours, in "
        "the yard as it stands under the place's dusk, rendered in Blender; nothing is seen in Studio. The white "
        "figures are a player's size. Triangles, a stage's pieces together, before the drawn edge's hull: " +
        ", ".join(f"Stage {k} {tris[k]:,}" for k in keys) + "."]
    lines = [ln for n in notes for ln in textwrap.wrap(n, 230)]
    gap = 16
    cw, ch = round(w * 2 / 3), round(h * 2 / 3)           # 640 by 360: about a phone's screen in points
    start_scale = 1.0                                     # the start view's machine, at its own size on a 960 by 540
    su, gu = union("start"), union("gate")
    start_h = round((su[3] - su[1]) * start_scale)
    small_h = start_h + 128 + 3 * gap + 24
    width = 3 * cw + 4 * gap
    height = 48 + 2 * (ch + 34) + 34 + small_h + 34 + ch + 34 + len(lines) * 19 + 24
    ui.K = 1
    page = ui.Sheet(width, height, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 14, 20, "Grow your Anime, the Void Breaker's stages: the Great Jaws (AR32)", "#EDE6D6", bold=0.2)
    for row, (name, caption) in enumerate((("start", "from the game's start camera on the spawn, at a phone's 640 by 360"),
                                           ("gate", "from a player inside the gate"))):
        y = 48 + row * (ch + 34)
        for i, k in enumerate(keys):
            x = gap + i * (cw + gap)
            t.text(x, y, 14, f"{titles[i]}, {caption}" if i == 0 else titles[i], "#B4AC9C")
            rs.paste(page.px, rs.shrink(shots[(k, name)], 2 / 3), x, y + 22)
    y = 48 + 2 * (ch + 34) + 8
    t.text(gap, y, 14, "From the spawn, the machine as a 960 by 540 screen draws it, and in black; from the gate, cut at one "
                        "scale for the three, 64 and 128 px tall over the dark, and in black", "#B4AC9C")
    x = gap
    for i, k in enumerate(keys):
        x0 = x
        for px in (cut(shots[(k, "start")], su, start_scale), cut(black[(k, "start")], su, start_scale)):
            rs.paste(page.px, px, x, y + 26)
            x += px.shape[1] + 8
        right = x
        x = x0
        g64 = 64 / (gu[3] - gu[1])
        for px in (cut(shots[(k, "gate")], gu, g64), cut(black[(k, "gate")], gu, g64),
                   cut(shots[(k, "gate")], gu, 2 * g64), cut(black[(k, "gate")], gu, 2 * g64)):
            rs.paste(page.px, px, x, y + 26 + start_h + gap)
            x += px.shape[1] + 8
        t.text(x0, y + 26 + start_h + gap + 128 + gap, 13, titles[i].split(",")[0], "#EDE6D6")
        x = max(x, right) + 2 * gap
    y += small_h + 34
    t.text(gap, y, 14, "Stage II at levels 6 and 7, from the gate: chamber 3's seat shut by its lid until level 8 (chamber "
                        "4's the same at Stage III until 20)", "#B4AC9C")
    rs.paste(page.px, rs.shrink(shots[("IIshut", "gate")], 2 / 3), gap, y + 22)
    y += ch + 34
    for i, ln in enumerate(lines):
        t.text(gap, y + i * 19, 14, ln, "#B4AC9C")
    for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
        rs.paste(page.px, layer, 0, 0)
    rs.save(page.px, out / "breaker_stages.png")
    for (key, name), px in shots.items():
        rs.save(px, out / f"breaker_{key}_{name}.png")
    print("triangles:", tris)


def main():
    import blcommon as bl
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    review(out, "fast" in args)


if __name__ == "__main__":
    main()
