"""AR15, section 7: the Festival Door drawn again, three directions in grey, for research's verdict. Throwaway: plain
concrete, a warm white light, a blank plate where the name goes, nothing polished and nothing exported.

The base's own scene (base_plan.see's), with the Door's two pieces swapped for each take where the Door stands (the
plot's -26, 46, turned 90, so its front looks across at the way in). In each take's own frame the front faces -Y, its
depth runs back along +Y, and its feet are on z = 0, as the kit's pieces.

  A, the deep gate     a thick gate whose way is a passage, lined with pointed frames of light that close in toward a
                       warm veil at its back
  B, the break         no building: the air broken like glass or rock, its rim stepping back and in, in three jagged
                       rings of flat facets, to a bright warm heart, and broken stones floating round it
  C, the ring tunnel   an upright stone ring on a low step, and four smaller rings floating behind it, each further back
                       and a little higher, a tunnel to a warm disc of light

    blender -b --factory-startup --python tools/blender/base_door_block.py -- build/handoff/Base [view ...] [fast]

Writes door_block_<view>.png for each view: the Door as it stands now, then A, B and C, in a grid. Eevee, no GPU turn.
The views are the game's camera: `home` from the spawn; `way` from the way in, straight on; `close` six studs from its
front, the camera tipped up a little as a player looks at a tall thing; `side` the base's own look at the Door.
"""
import math
import random
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_plan as plan  # noqa: E402

base, bl, kit, look, rs = plan.base, plan.bl, plan.kit, plan.look, plan.rs
machines = base.machines
Mesh = machines.Mesh
STONE, PALE, PLATE = "concrete", "ceramic", "rubber"
WARM = "#FFE6C4"            # the light each take throws, a warm white
# Its own lit parts, each its own glow: lines bright, what lies deep softer, so the depth reads and nothing burns white.
GLOWS = {"line": ("#FFF0D8", 2.2), "veil": ("#FFC98E", 1.1), "rim": ("#FFD9A6", 1.0), "heart": ("#FFF1DC", 1.8),
         "disc": ("#FFD39A", 1.4)}
TAKES = ("now", "A", "B", "C")


# --- the shapes ------------------------------------------------------------------------------------------------------

def face(m, pts, sw, toward, t=None):
    """One face in a swatch, turned so it looks along `toward`. Light swatches take their head's colour all over."""
    pts = [Vector(p) for p in pts]
    n = (pts[1] - pts[0]).cross(pts[2] - pts[0])
    if n.length < 1e-9:
        n = (pts[2] - pts[0]).cross(pts[-1] - pts[0])
    if n.dot(Vector(toward)) < 0:
        pts = pts[::-1]
    m.face(pts, [kit.sw_uv(sw, 0.0, t if t is not None else min(max(p.z / 14.0, 0.0), 1.0)) for p in pts])


class Glows(dict):
    """A take's lit parts, a mesh for each glow in GLOWS, made as they're asked for."""

    def __missing__(self, key):
        self[key] = Mesh(None)
        return self[key]


def band(m, outer, inner, y0, y1, sw, centre, closed, sink=0.0, rim=None):
    """A slab with a hole: `outer` and `inner` are lines in X and Z of as many points, the hole's edge `inner`. Its
    front at y0, its back at y1; with `sink` the inner edge lies that much further back, so the front is a funnel of
    flat facets. Open lines get their two ends. `rim`: the inner edge's own swatch."""
    c = Vector((centre[0], 0.0, centre[1]))
    k = len(outer)
    pairs = [(i, (i + 1) % k) for i in range(k if closed else k - 1)]

    def at(q, y):
        return Vector((q[0], y, q[1]))

    for i, j in pairs:
        oi, oj, ii, ij = outer[i], outer[j], inner[i], inner[j]
        face(m, [at(oi, y0), at(oj, y0), at(ij, y0 + sink), at(ii, y0 + sink)], sw, (0, -1, 0.0001))
        face(m, [at(oi, y1), at(oj, y1), at(ij, y1 + sink), at(ii, y1 + sink)], sw, (0, 1, 0.0001))
        mid = (at(oi, y0) + at(oj, y0)) / 2
        face(m, [at(oi, y0), at(oj, y0), at(oj, y1), at(oi, y1)], sw, mid - c)
        mid = (at(ii, y0) + at(ij, y0)) / 2
        face(m, [at(ii, y0 + sink), at(ij, y0 + sink), at(ij, y1 + sink), at(ii, y1 + sink)], rim or sw, c - mid)
    if not closed:
        for i, toward in ((0, None), (k - 1, None)):
            o, n = outer[i], inner[i]
            side = Vector((o[0] - n[0], 0, o[1] - n[1])).cross(Vector((0, 1, 0)))
            face(m, [at(o, y0), at(n, y0 + sink), at(n, y1 + sink), at(o, y1)], sw, side if i else -side)


def arch(w, spring, rise, n=10, lift=0.0):
    """A pointed arch's line, foot left round to foot right: straight sides up to `spring`, then two arcs to a point
    `rise` over it (an equilateral arch's arcs, squashed or stretched to that rise)."""
    left = [(-w, lift)]
    for k in range(n + 1):
        a = math.radians(180.0 - 60.0 * k / n)               # the left arc: centred on (w, spring), radius 2w
        x, z = w + 2 * w * math.cos(a), 2 * w * math.sin(a)
        left.append((x, lift + spring + z * rise / (math.sqrt(3) * w)))
    return left + [(-x, z) for x, z in reversed(left[:-1])]


def circle(r, centre, n=40, start=0.0, end=360.0):
    cx, cz = centre
    closed = end - start >= 360.0
    steps = n if closed else max(2, round(n * (end - start) / 360.0))
    return [(cx + r * math.cos(math.radians(start + (end - start) * i / steps)),
             cz + r * math.sin(math.radians(start + (end - start) * i / steps))) for i in range(steps if closed else steps + 1)]


def plate(m, front, top):
    """Where the name goes: a blank plate, dark, floating over the take. The name itself is Faber's, in the UI kit."""
    m.box((5.0, 0.3, 1.2), (0, front, top + 1.6), PLATE, ink=True)


def take_a():
    """The deep gate: four frames, front to back, each a pointed slab 1.6 deep, the passage through them closing in.
    A line of light on each frame's inner edge, and a warm veil across the last."""
    m, g = Mesh(), Glows()
    m.box((16.0, 9.0, 0.5), (0, 0.6, 0.25), STONE, ink=True)                  # the step it stands on
    outer = arch(7.2, 8.0, 7.0, lift=0.5)                                     # its outline, 15.5 up at its point
    depth, front = 1.6, -3.6
    for k in range(4):
        y = front + depth * k
        w, s = 4.4 - 0.4 * k, 6.2 - 0.4 * k
        inner = arch(w, s, 0.75 * math.sqrt(3) * w, lift=0.5)
        band(m, outer, inner, y, y + depth, STONE, (0, 6.0), closed=False)
        glow = arch(w + 0.16, s, 0.75 * math.sqrt(3) * (w + 0.16), lift=0.5)
        g["line"].tube([(x, y - 0.1, z) for x, z in glow[1:-1]], 0.12, PALE)
    face(g["veil"], [(x, front + 4 * depth - 0.05, z) for x, z in inner], PALE, (0, -1, 0))
    plate(m, front - 0.4, 15.5)
    return m, g, [((0, 1.4, 5.0), 36.0, 30.0), ((0, -5.5, 3.0), 12.0, 16.0)]


def jagged(scale, seed, n=13, wide=1.18, base_r=4.6, centre=(0.0, 6.2)):
    """The break's line: straight edges between points at their own angles, every other one thrust out, wider than
    tall. One seed per ring, so no two rings' facets line up."""
    rng = random.Random(seed)
    pts = []
    for i in range(n):
        a = 2 * math.pi * (i + 0.5 * rng.random() - 0.25) / n
        r = base_r * scale * ((1.16 + 0.14 * rng.random()) if i % 2 else (0.86 + 0.08 * rng.random()))
        pts.append((centre[0] + wide * r * math.cos(a), centre[1] + r * math.sin(a)))
    return pts


def take_b():
    """The break: three jagged rings of flat facets, each further back and further in, the outer stone, the middle
    pale stone, the inner lit; a bright heart behind them; broken stones floating round."""
    m, g = Mesh(), Glows()
    m.lathe([(5.2, 0.35), (5.8, 0.0)], (0, 0.4, 0), 7, STONE, spin=0.3)        # a low broken footing
    rings = [(1.32, 1.02, -1.2, m, STONE), (1.10, 0.80, -0.4, m, PALE), (0.88, 0.60, 0.4, g["rim"], PALE)]
    for k, (out_s, in_s, y, into, sw) in enumerate(rings):
        outer, inner = jagged(out_s, 10 + k), jagged(in_s, 20 + k)
        band(into, outer, inner, y, y + 0.5, sw, (0.0, 6.2), closed=True, sink=0.35)
    face(g["heart"], [(x, 1.15, z) for x, z in jagged(0.66, 30)], PALE, (0, -1, 0))
    rng = random.Random(7)
    for i in range(8):                                                       # the broken stones, flying off it
        a = math.radians(i * 45 + rng.uniform(-14, 14))
        d = Vector((math.cos(a) * 1.18, 0, math.sin(a)))
        r = 7.2 + rng.uniform(-0.5, 1.4)
        mid = Vector((0, rng.uniform(-1.4, 0.8), 6.2)) + d * r
        if mid.z < 1.0:
            continue
        size = rng.uniform(0.35, 0.65)
        machines.horn(m, [mid - d * size * 2.2, mid, mid + d * size * 1.4], [0.03, size, 0.03], STONE, deep=0.8)
    plate(m, -1.6, 12.4)
    return m, g, [((0, -1.2, 6.2), 36.0, 30.0), ((0, -4.5, 2.5), 12.0, 14.0)]


def take_c():
    """The ring tunnel: a plain stone ring half sunk in a low step, and four rings floating behind it, each smaller,
    further back and a little higher and to one side, each broken by gaps of its own, so a turn would show. A line of
    light round each inner edge, and a warm disc at the end."""
    m, g = Mesh(), Glows()
    m.box((14.0, 4.0, 0.6), (0, -0.6, 0.3), STONE, ink=True)                   # the step, under the front ring only
    zc = 0.6 + 5.0
    band(m, circle(6.4, (0, zc)), circle(5.0, (0, zc)), -1.0, 0.6, STONE, (0, zc), closed=True)
    g["line"].tube([(x, -1.08, z) for x, z in circle(5.12, (0, zc))] + [(5.12, -1.08, zc)], 0.1, PALE)
    gaps = [(20, 135, 150, 262, 280, 350), (70, 170, 190, 300, 318, 410), (-30, 95, 112, 200, 222, 316),
            (40, 150, 168, 280, 296, 388)]
    for k, (y, r) in enumerate(((1.7, 5.3), (3.0, 4.4), (4.1, 3.6), (5.0, 2.9))):
        c = (0.25 * (k + 1), zc + 0.35 * (k + 1))
        cuts = gaps[k]
        for a0, a1 in zip(cuts[0::2], cuts[1::2]):                          # three arcs a ring, gaps of their own
            band(m, circle(r, c, 44, a0, a1), circle(r - 0.6, c, 44, a0, a1), y, y + 0.45, STONE, c, closed=False)
            g["line"].tube([(x, y - 0.06, z) for x, z in circle(r - 0.5, c, 44, a0 + 3, a1 - 3)], 0.07, PALE)
    disc = (0.25 * 5, zc + 0.35 * 5)
    face(g["disc"], [(x, 5.9, z) for x, z in circle(2.4, disc, 32)], PALE, (0, -1, 0))
    plate(m, -1.4, zc + 6.4)
    return m, g, [((0.6, 3.0, zc + 0.8), 36.0, 30.0), ((0, -4.0, 2.5), 12.0, 14.0)]


BUILD = {"A": take_a, "B": take_b, "C": take_c}


# --- the scene -------------------------------------------------------------------------------------------------------

def player_view(at, toward, pitch=20.0, lift=0.0):
    """The game's camera behind a player at `at` (world X, Y) looking toward `toward`: Roblox's start zoom, the
    replay's pitch. `lift` raises where the camera looks, studs over the player's focus."""
    p = math.radians(pitch)
    focus = Vector((at[0], at[1], 3.0 + look.FOCUS))
    d = Vector((toward[0] - at[0], toward[1] - at[1], 0)).normalized()
    eye = focus - d * math.cos(p) * look.ZOOM + Vector((0, 0, math.sin(p) * look.ZOOM))
    return tuple(eye), tuple(focus + Vector((0, 0, lift)) + d * 4.0)


def scene_up(fast):
    """base_plan.see's scene, level 1, without its renders."""
    d = look.DIRECTIONS["M"]
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1], azimuth=d.get("glow_az", 0.0),
                    away=look.srgb(d["fog_away"]) if "fog_away" in d else None)
    scene = bl.reset_scene()
    out = bl.out_dir()
    base.write_pictures(out / "maps")
    yard = plan.Yard(scene, 1, out / "maps")
    yard.plot(0.0, 1)
    yard.plot(plan.STRIP, -1)
    yard.kit.block("Strip", (3 * plan.PLOT, plan.STRIP, 0.4), (0, plan.STRIP / 2, -0.22), yard.stone)
    yard.kit.block("Ground", (5 * plan.PLOT, 4 * plan.PLOT, 0.4), (0, plan.STRIP / 2, -0.3), yard.flat["ground"])
    yard.person((plan.SPAWN[0], -plan.SPAWN[1]))
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


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    fast = "fast" in args
    scene, yard, d = scene_up(fast)
    dx, dy = plan.DOOR[0], -plan.DOOR[1]
    yard.person((dx + 20.0, dy), "WayIn")                                    # where `way` stands, and `close`
    yard.person((dx + 6.0, dy), "Close")
    views = {"home": plan.behind((plan.SPAWN[0], -plan.SPAWN[1]), -1),
             "way": player_view((dx + 20.0, dy), (dx, dy)),
             "close": player_view((dx + 6.0, dy), (dx, dy), pitch=8.0, lift=3.0),
             "side": ((dx + 20.0, dy + 9.0, 6.0), (dx, dy, 6.6))}
    only = [a for a in args if a in views]
    views = {name: views[name] for name in (only or views)}
    doors = [o for o in yard.kit.pieces if o.name.startswith("Door_")]
    ways = [o for o in yard.kit.pieces if o.name.startswith("DoorWay_")]
    material = yard.stock.mats["Kit"]
    kept = {o.name: o.data for o in doors}
    shots = {}
    for take in TAKES:
        lamps = []
        if take == "now":
            for o in doors:
                o.data = kept[o.name]
            for o in ways:
                o.hide_render = False
        else:
            base.wear()
            m, glows, lights = BUILD[take]()
            data = m.whole().to_object(f"Door{take}", material)
            lit = {key: g.whole().to_object(f"Door{take}{key}", look.glowing(f"Door{take}{key}", *GLOWS[key]))
                   for key, g in glows.items()}
            for o in ways:
                o.hide_render = True
            for o in doors:
                o.data = data
                for key, part in lit.items():
                    shine = bpy.data.objects.new(f"{key}{o.name}", part)
                    shine.location, shine.rotation_euler = o.location, o.rotation_euler
                    scene.collection.objects.link(shine)
                    lamps.append(shine)
                turn = Matrix.Rotation(o.rotation_euler.z, 3, "Z")
                for i, (at, watts, reach) in enumerate(lights):
                    lamp = look.light(yard.kit, scene, f"Lamp{take}{o.name}{i}", tuple(o.location + turn @ Vector(at)),
                                      WARM, watts * kit.REAL_LIGHT, reach)
                    lamp.data.use_shadow = False
                    lamps.append(lamp)
        for name, (eye, target) in views.items():
            scene.camera = plan.camera(scene, f"{name}{take}", eye, target)
            linear = look.render_linear(scene, out / f"door_block_{take}_{name}.exr")
            shots[take, name] = look.finish(linear, d)
            (out / f"door_block_{take}_{name}.exr").unlink(missing_ok=True)
        for lamp in lamps:
            bpy.data.objects.remove(lamp, do_unlink=True)
    for name in views:
        top = np.concatenate([shots["now", name], shots["A", name]], axis=1)
        foot = np.concatenate([shots["B", name], shots["C", name]], axis=1)
        rs.save(np.concatenate([top, foot], axis=0), out / f"door_block_{name}.png")


if __name__ == "__main__":
    main()
