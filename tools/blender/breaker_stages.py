"""AR32: the Void Breaker's Stages II and III, two directions for how it grows, in grey beside Stage I
(docs/asset-requests.md, AR32, "The two directions, planned").

blender.exe -b --factory-startup --python tools/blender/breaker_stages.py -- <out_dir> [fast]

Each stage is a block in the base kit's grey (its stone, steel and bone drawn in the kit's concrete and ceramic), with
only the void's light lit, stood where the Breaker stands in the yard as it is, and seen:
  - from the game's start camera: the player on the spawn, turned to the Breaker as the spawn faces it;
  - from a player at the gate before the Breaker, the camera turned to it;
  - cut to the machine at 64 and 128 px tall, and in black, from the gate's view.
It writes each view, and a sheet a direction (breaker_A.png, breaker_B.png).

Both directions keep the chambers' places: 1 and 2 where they stand, 3 and 4 on along the line outward, 7 studs apart
(chamber 3 with Stage II, opening at machine level 8; chamber 4 with Stage III, at level 20). The body grows a section a
chamber and stays 5 high, so a chamber's foot and its shard's room are where they are today. The waiting line's three
cradles move to the body's front foot. Every new fang hangs down to its shard, as today.

  A, the Great Jaws   The jaws grow with the line: they root at its two ends and arch over all of it to a gap over its
                      middle, where the crystal floats; two lower jaws meet under them in a bone clamp, and each
                      chamber's fang hangs from them. Stage III adds a barb to each jaw and two small claws round
                      the crystal.
  B, the Gear Train   A gear of void stone over each chamber, with a pinion between each two so the train rolls, on a
                      beam the end jaws hold; each chamber's fang hangs from its gear's hub. Stage III adds an inner
                      ring to each gear, turning the other way, horns over the pinions, legs and clamps under the beam,
                      and two horns holding the crystal.

The content check of 2026-11-17 on the plan holds:
  - the crystal stays a faceted lozenge, held between a mirrored pair, never a star or rays;
  - a gear's spokes are straight and radial, six of them or a solid web, never four in a cross;
  - fangs, jaws, claws and clamps are clean stone or bone, with no glow at any tip;
  - no brass or copper clockwork, and no stage becomes a tall tapering tower with a lit crown.
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
from base_mill import FACING, UP, Mesh, at, bar, disc, put, toothed  # noqa: E402
import base_plan as plan  # noqa: E402
import blcommon as bl  # noqa: E402
import lantern_row_kit as kit  # noqa: E402
import lantern_row_look as look  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402

BX, BI = plan.BREAKER                 # the Breaker's place: across, and in from the front edge
STEP, FIRST = 7.0, -3.5               # the chambers along the line: their step, and chamber 1's place
FOOT = bm.BODY[2]                     # the body's top, where a chamber stands
FANG_TIP = bm.GAP[1] + 0.12           # a fang's point, over the shard's room
GREY = {"steel": "concrete", "girder": "concrete", "abyss": "concrete", "yellow": "concrete", "copper": "concrete",
        "bone": "ceramic"}            # the block's grey; the void's light, the dark and the ink keep their own
GEAR, PINION = (2.45, 14), (1.05, 6)  # B's train: pitch radius and teeth. 2.45 + 1.05 is half the step, so it rolls
TRAIN_Y = -2.1                        # B's gears' plane, behind the chambers' claws
STAGES = {"A": "the Great Jaws", "B": "the Gear Train"}


class Grey:
    """While it's open, every swatch a block asks for is drawn in the block's grey."""

    def __enter__(self):
        self.own = kit.sw_uv
        kit.sw_uv = lambda name, occ, t: self.own(GREY.get(name, name), occ, t)

    def __exit__(self, *_):
        kit.sw_uv = self.own


def chambers(n):
    return [FIRST + STEP * k for k in range(n)]


def span(n):
    """The body's two ends along the line."""
    return -7.0, FIRST + STEP * (n - 1) + 3.5


# --- what both directions share ----------------------------------------------------------------------------------------

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


def line(m, n, stage):
    """The chambers on the body's top, and the waiting line: along the line's end at Stage I, at the body's front foot
    after it."""
    for x in chambers(n):
        put(m, bm.breaker_chamber().mesh, at(x, 0, FOOT))
    waiting = bm.breaker_waiting().mesh
    if stage == 1:
        places = [(9.0 + 3.0 * k, 0.0) for k in range(3)]
    else:
        xc = sum(span(n)) / 2
        places = [(xc + 3.0 * (k - 1), 5.1) for k in range(3)]
    for x, y in places:
        put(m, waiting, at(x, y, 0))


def fang(m, x, top, clamp=True):
    """A chamber's fang from `top` down to its shard, unlit, a bone clamp where it hangs."""
    bm.horn(m, [(x, 0, top), (x, 0, FANG_TIP)], [0.5, 0.05], "abyss")
    if clamp:
        m.box((0.6, 1.25, 0.9), (x, 0, top + 0.1), "bone", ink=True)


# --- A, the Great Jaws -------------------------------------------------------------------------------------------------

def under(d, half, low):
    """The lower jaw's height `d` out from the middle: an arch under the upper jaws, `low` where the two meet."""
    return low - 1.6 * (d / half) ** 2


def jaws(stage, n):
    m = Mesh()
    body(m, n)
    x0, x1 = span(n)
    xc, half = (x0 + x1) / 2, (x1 - x0) / 2
    if stage == 2:
        reach = [(half - 0.4, FOOT), (half + 0.9, 9.6), (half - 0.5, 13.4), (6.2, 15.1), (2.4, 15.4)]
        widths, low, crystal = [1.0, 0.95, 0.8, 0.5, 0.06], 11.2, (14.4, 1.3, 5.0)
    else:
        reach = [(half - 0.4, FOOT), (half + 1.0, 10.4), (half - 0.4, 15.2), (8.8, 17.2), (2.6, 17.6)]
        widths, low, crystal = [1.2, 1.1, 0.95, 0.6, 0.07], 12.4, (15.8, 1.5, 6.0)
    for s in (-1, 1):
        upper = [(xc + s * d, 0, z) for d, z in reach]
        m.box((2.2, 2.4, 0.4), (upper[0][0], 0, FOOT + 0.2), "girder", ink=True)
        bm.horn(m, upper, widths, "abyss", deep=0.8)
        bm.vein(m, upper[:4] + [(xc + s * (reach[4][0] + 1.4), 0, reach[4][1] - 0.4)], widths[:4] + [0.3], (xc, 0, 9.0))
        lower = [(xc + s * (half + 0.2), 0, 8.4)] + [(xc + s * d, 0, under(d, half, low)) for d in (0.75 * half, 0.4 * half, 0.5)]
        bm.horn(m, lower, [0.75, 0.62, 0.45, 0.3], "abyss", deep=0.9)   # the lower jaw, arched under the upper
        hinge = toothed(1.0, 10, 0.3, 0.32)                  # the jaw's hinge: a solid web, its teeth round it
        disc(hinge, (0, 0, 0.2), 0.34, 0.2, "bone", axis=(0, 0, 1))
        put(m, hinge, at(upper[0][0] - s * 0.3, 1.15, 6.3) @ FACING)
        if stage == 3:                                        # a barb from the jaw's elbow, up and out
            ex, ez = reach[1]
            bm.horn(m, [(xc + s * (ex - 0.3), 0, ez), (xc + s * (ex + 1.6), 0, ez + 3.4), (xc + s * (ex + 2.2), 0, ez + 5.2)],
                    [0.7, 0.4, 0.05], "abyss", deep=0.8)
            bm.horn(m, [(xc + s * 0.6, 0, low + 0.6), (xc + s * 1.9, 0, low + 2.4), (xc + s * 1.3, 0, low + 4.0)],
                    [0.35, 0.3, 0.05], "abyss", deep=0.8)    # the crystal's two small claws
    m.box((1.6, 1.4, 1.1), (xc, 0, low + 0.1), "bone", ink=True)  # where the lower jaws meet
    for x in chambers(n):
        fang(m, x, under(abs(x - xc), half, low) - 0.1, clamp=abs(x - xc) > 0.6)
    bm.shard(m, (xc, 0, crystal[0]), crystal[1], crystal[2], "cyan")
    line(m, n, stage)
    return m, (xc, 0.0, crystal[0])


# --- B, the Gear Train -------------------------------------------------------------------------------------------------

def gear(r, teeth, phase=0.0, inner=False):
    """A gear of void stone about Z: its rim and teeth, six straight spokes and a hub; with `inner`, a ring in front of
    the spokes that turns the other way."""
    g = toothed(r, teeth, 0.5, r - 0.85) if r > 2 else toothed(r, teeth, 0.5, 0.2)
    if r > 2:
        for k in range(6):
            a = math.tau * k / 6 + math.pi / 6
            out = Vector((math.cos(a), math.sin(a), 0.0))
            bar(g, out * 0.5, out * (r - 0.8), 0.34, "abyss", d=0.36)
    disc(g, (0, 0, 0), 0.62 if r > 2 else 0.4, 0.66, "abyss", axis=(0, 0, 1))
    if inner:
        bm.hoop(g, (0, 0, 0.42), 1.0, 1.45, 0.26, 12, "abyss", lying=True)
    return put_turned(g, phase)


def put_turned(g, phase):
    m = Mesh()
    put(m, g, Matrix.Rotation(phase, 4, "Z"))
    return m


def train(stage, n):
    m = Mesh()
    body(m, n)
    x0, x1 = span(n)
    xc = (x0 + x1) / 2
    hub = 11.3 if stage == 2 else 11.6
    back = -2.75
    m.box((x1 - x0 - 1.0, 0.6, 1.2), (xc, back, hub), "abyss", ink=True)         # the beam the axles turn in
    for k, x in enumerate(chambers(n)):
        put(m, gear(*GEAR, inner=stage == 3), at(x, TRAIN_Y, hub) @ FACING)
        bar(m, (x, TRAIN_Y + 0.3, hub), (x, 0.35, hub), 0.5, "bone")          # the axle's stub, out over the shard
        fang(m, x, hub - 0.3, clamp=False)
        if k < n - 1:
            put(m, gear(*PINION, phase=math.pi / PINION[1]), at(x + STEP / 2, TRAIN_Y, hub) @ FACING)
    top = hub + GEAR[0] + 0.32
    for end, s in ((x0, -1), (x1, 1)):                     # Stage I's jaws at the line's ends, holding the beam
        lift = 0.0 if stage == 2 else 1.2
        jaw = [(end - s * 0.4, back, FOOT), (end + s * 0.6, back, 8.6), (end - s * 0.2, back, top - 0.4 + lift),
               (end - s * 2.6, back, top + 0.9 + lift)]
        m.box((1.9, 1.4, 0.4), (end - s * 0.4, back, FOOT + 0.2), "girder", ink=True)
        bm.horn(m, jaw, [0.9, 0.85, 0.7, 0.06], "abyss", deep=0.8)
        bm.vein(m, jaw[:3] + [(end - s * 1.6, back, top + 0.4 + lift)], [0.9, 0.85, 0.7, 0.3], (xc, back, hub))
        m.box((1.2, 1.0, 1.6), (end - s * 0.3, back, hub), "bone", ink=True)     # its clamp on the beam's end
    if stage == 2:
        bm.shard(m, (xc, -1.2, top + 2.9), 1.2, 5.0, "cyan")
        lamp = (xc, -1.2, top + 2.9)
    else:
        for k in range(n - 1):
            x = FIRST + STEP * k + STEP / 2
            m.box((0.8, 0.6, hub - 0.6 - FOOT), (x, back, (FOOT + hub - 0.6) / 2), "girder", ink=True)   # a leg
            for z in (FOOT + 0.35, hub - 0.95):
                m.box((1.1, 0.9, 0.5), (x, back, z), "bone", ink=True)               # its clamps
            if abs(x - xc) > 0.6:                                                    # horns over the pinions
                bm.horn(m, [(x, back, hub + 0.6), (x, back, top + 1.6)], [0.42, 0.05], "abyss")
        for s in (-1, 1):                                                            # two horns hold the crystal
            bm.horn(m, [(xc + s * 1.0, back, hub + 0.6), (xc + s * 2.3, back, hub + 4.4), (xc + s * 1.3, back, hub + 7.2)],
                    [0.5, 0.4, 0.05], "abyss", deep=0.8)
        bm.shard(m, (xc, back, hub + 5.2), 1.4, 6.0, "cyan")
        lamp = (xc, back, hub + 5.2)
    line(m, n, stage)
    return m, lamp


def stage_one():
    m = Mesh()
    put(m, bm.breaker().mesh, at(0, 0, 0))
    line(m, 2, 1)
    return m, (0.0, 0.0, 10.2)


BUILD = {"A": jaws, "B": train}


# --- the yard, the views and the sheets ----------------------------------------------------------------------------

def yard_without_breaker(out: Path, fast):
    """base_plan's look as it stands, its Breaker, chambers and waiting line taken out."""
    made = plan.machines
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
    yard.person(GATE_PLAYER, "Near")
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


GATE_PLAYER = (BX + 4.0, -(BI - 12.0))   # a player inside the gate, before the Breaker's middle: the camera behind
                                         # them stands just inside the front wall


def views():
    pitch = math.radians(20.0)
    spawn = Vector((base.SPAWN[0], -base.SPAWN[1], 3.0 + look.FOCUS))
    flat = Vector((BX - spawn.x, -BI - spawn.y, 0.0)).normalized()
    start = (tuple(spawn - flat * math.cos(pitch) * look.ZOOM + UP * math.sin(pitch) * look.ZOOM), tuple(spawn))
    near = Vector((*GATE_PLAYER, 3.0 + look.FOCUS))
    flat = Vector((0.0, -1.0, 0.0))
    gate = (tuple(near - flat * math.cos(pitch) * look.ZOOM + UP * math.sin(pitch) * look.ZOOM), (BX + 4.0, -BI, 9.0))
    return {"start": start, "gate": gate}


class Shots:
    def __init__(self, out, scene, yard, d):
        self.out, self.scene, self.yard, self.d = out, scene, yard, d
        self.views = views()
        self.made, self.tris, self.boxes, self.black = {}, {}, {}, {}

    def take(self, key, mesh, n, lamp):
        data = mesh.whole().to_object(f"Breaker{key}", self.yard.stock.mats["Kit"])
        obj = bpy.data.objects.new(f"Breaker{key}", data)
        obj.location = (BX, -BI, 0.0)
        self.scene.collection.objects.link(obj)
        self.tris[key] = mesh.whole().tris()
        shards = [self.yard.kit.block(f"Shard{key}{k}", (1.0, 1.0, 1.7), (BX + x, -BI, sum(bm.GAP) / 2), self.yard.flat["chamber"])
                  for k, x in enumerate(chambers(n)) if k >= 2]
        light = bpy.data.objects.get("BreakerLampA")              # the Breaker's lamp, on this stage's crystal
        if light is not None:
            light.location = (BX + lamp[0], -BI + lamp[1], lamp[2])
        bpy.context.view_layer.update()
        for name, (eye, target) in self.views.items():
            self.scene.camera = plan.camera(self.scene, f"Cam{key}{name}", eye, target)
            path = self.out / f"breaker_{key}_{name}.png"
            linear = look.render_linear(self.scene, path.with_suffix(".exr"))
            px = look.finish(linear, self.d)
            rs.save(px, path)
            path.with_suffix(".exr").unlink(missing_ok=True)
            self.made[(key, name)] = px
            if name == "gate":
                self.boxes[key] = self.frame_box(obj)
                self.black[key] = self.silhouette(obj, self.out / f"breaker_{key}_black.png")
        for shard in shards:
            bpy.data.objects.remove(shard)
        bpy.data.objects.remove(obj)
        bpy.data.meshes.remove(data)

    def frame_box(self, obj):
        """The machine's box in the gate's view, in pixels: left, top, right, bottom."""
        w, h = look.SIZE
        pts = [world_to_camera_view(self.scene, self.scene.camera, obj.matrix_world @ v.co) for v in obj.data.vertices]
        xs, ys = [p.x * w for p in pts], [(1 - p.y) * h for p in pts]
        return min(xs), min(ys), max(xs), max(ys)

    def silhouette(self, obj, path):
        """The machine alone from the same camera, black on white."""
        scene, r = self.scene, self.scene.render
        hidden = [o for o in scene.objects if o is not obj and o.type == "MESH" and not o.hide_render]
        for o in hidden:
            o.hide_render = True
        engine = r.engine
        r.engine = "BLENDER_WORKBENCH"
        r.film_transparent = True
        r.image_settings.file_format, r.image_settings.color_mode = "PNG", "RGBA"
        r.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        r.engine, r.film_transparent = engine, False
        for o in hidden:
            o.hide_render = False
        px = rs.load(path)
        a = px[..., 3:4]
        black = np.ones_like(px)
        black[..., :3] = 1.0 - a
        rs.save(black, path)
        return black


def cut(px, box, tall):
    """The union box cut from a view, shrunk so it stands `tall` pixels."""
    x0, y0, x1, y1 = (int(v) for v in box)
    piece = px[max(y0, 0):y1, max(x0, 0):x1]
    return rs.shrink(piece, tall / piece.shape[0])


NOTES = {
    "A": ("The jaws grow with the line. At Stage II they root at its two ends and arch over all three chambers to a gap "
          "over the middle, where the crystal floats. Two lower jaws meet under them in a bone clamp, and each chamber's "
          "fang hangs from them. A hinge gear sits on each jaw's root. At Stage III the jaws reach 17.6, each grows a "
          "barb from its elbow, and two small claws hold the crystal.",
          "The motion, for the build: each hinge gear turns while its side's chambers break, and the jaws hold still. "
          "The read from the gate: one great pair of horns over the line, the crystal in their gap, its size the stage."),
    "B": ("The void's work shows in turning gears. At Stage II a gear of void stone stands over each chamber, a pinion "
          "between each two so the train rolls, on a beam behind the chambers that Stage I's two jaws hold at the "
          "line's ends. Each chamber's fang hangs from its gear's hub, and the crystal floats over the middle. At "
          "Stage III each gear has an inner ring that turns the other way, horns stand over the pinions, legs with bone "
          "clamps carry the beam, and two horns hold the crystal.",
          "The motion, for the build: the gears turn, each against its neighbour, faster while more chambers break. "
          "The read from the gate: a row of wheels over the chambers, their count the chambers'."),
}
SHARED = ("Both: chambers 1 and 2 stand where they stand, and 3 and 4 go on along the line outward, 7 studs apart "
          "(chamber 3 with Stage II, open from level 8; chamber 4 with Stage III, from level 20). The body grows a "
          "section a chamber and stays 5 high. The waiting line's three cradles move to the body's front foot. Every "
          "chamber is shown open. Grey blocks in the base kit's swatches, with only the void's light lit, in the yard as "
          "it stands under the place's dusk, rendered in Blender; nothing is seen in Studio. The white figures are a "
          "player's size.")


def sheet(out, key, shots):
    gap, (w, h) = 16, look.SIZE
    cw, ch = round(w * 2 / 3), round(h * 2 / 3)           # 640 by 360: about a phone's screen in points
    keys = ["I", f"{key}II", f"{key}III"]
    union = tuple(f(shots.boxes[k][i] for k in keys) for i, f in enumerate((min, min, max, max)))
    union = (union[0] - 6, union[1] - 6, union[2] + 6, union[3] + 6)
    lines = [ln for n in NOTES[key] + (SHARED + " Triangles, Stages I, II and III with the drawn edge: " +
                                       ", ".join(f"{shots.tris[k]:,}" for k in keys) + ".",) for ln in textwrap.wrap(n, 230)]
    small_h = 128 + 64 + 3 * gap + 40
    width = 3 * cw + 4 * gap
    height = 48 + 2 * (ch + 34) + 34 + small_h + len(lines) * 19 + 24
    page = ui.Sheet(width, height, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 14, 20, f"Grow your Anime, the Void Breaker's stages: {key}, {STAGES[key]}", "#EDE6D6", bold=0.2)
    titles = ("Stage I, as it stands (machine levels 1 to 5)", "Stage II, levels 6 to 14", "Stage III, levels 15 and up")
    for row, (name, caption) in enumerate((("start", "from the game's start camera on the spawn, at a phone's 640 by 360"),
                                           ("gate", "from a player at the gate before it"))):
        y = 48 + row * (ch + 34)
        for i, k in enumerate(keys):
            x = gap + i * (cw + gap)
            t.text(x, y, 14, f"{titles[i]}, {caption}" if i == 0 else titles[i], "#B4AC9C")
            rs.paste(page.px, rs.shrink(shots.made[(k, name)], 2 / 3), x, y + 22)
    y = 48 + 2 * (ch + 34) + 8
    t.text(gap, y, 14, "From the gate's view, cut to the machine at one scale for the three: 64 and 128 px tall over "
                        "the dark, and in black", "#B4AC9C")
    x = gap
    for i, k in enumerate(keys):
        tiles = [(cut(shots.made[(k, "gate")], union, 64), 0), (cut(shots.black[k], union, 64), 1),
                 (cut(shots.made[(k, "gate")], union, 128), 2), (cut(shots.black[k], union, 128), 3)]
        x0 = x
        for px, j in tiles[:2]:
            rs.paste(page.px, px, x, y + 26)
            x += px.shape[1] + 8
        x = x0
        for px, j in tiles[2:]:
            rs.paste(page.px, px, x, y + 26 + 64 + gap)
            x += px.shape[1] + 8
        t.text(x0, y + 26 + 64 + 128 + 2 * gap, 13, titles[i].split(",")[0], "#EDE6D6")
        x += gap * 2
    y += small_h
    for i, ln in enumerate(lines):
        t.text(gap, y + i * 19, 14, ln, "#B4AC9C")
    for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
        rs.paste(page.px, layer, 0, 0)
    rs.save(page.px, out / f"breaker_{key}.png")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    scene, yard, d = yard_without_breaker(out, "fast" in args)
    shots = Shots(out, scene, yard, d)
    with Grey():
        meshes = {"I": (stage_one(), 2)}
        for key, build in BUILD.items():
            meshes[f"{key}II"] = (build(2, 3), 3)
            meshes[f"{key}III"] = (build(3, 4), 4)
    for key, ((mesh, lamp), n) in meshes.items():
        shots.take(key, mesh, n, lamp)
    ui.K = 1
    for key in STAGES:
        sheet(out, key, shots)
    print("triangles:", shots.tris)


if __name__ == "__main__":
    main()
