"""AR15, section 7: the Festival Door's finish, C, the ring tunnel (research's pick, 2026-11-17), motion first. Grey still:
plain concrete and a warm white light, judged turning from the way in at a phone's size before any colour.

Research's fixes, carried here:
  1. The rings turn, each at its own rate. Straight on, the still block read close to a target; the turn must break it.
     If it doesn't, three rings, not five, before anything else: both are drawn, `five` (the front ring and four behind
     it) and `three` (the front ring and two).
  2. Apart from the generator's wheel beside it: the rings behind are thin lines of light on a thin stone back, with
     open gaps, never a dark face or spokes.
  3. The name's plate sits on the front ring's crown.
Kept from the block (tier 1): a warm light on the floor at the mouth; each ring's gaps its own, so a turn shows.

The base's own scene, as base_door_block.py has it, the Door swapped where it stands.

    blender -b --factory-startup --python tools/blender/base_door_turn.py -- <out> [seconds] [fast]

Writes door_turn_<take>.mp4 (the way in, at 24 a second), door_turn_strip.png (both takes at the way in, a second
apart) and door_turn_stills.png (both from the spawn and three-quarter on).
"""
import math
import shutil
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_door_block as db  # noqa: E402
import frames_to_movie as movie  # noqa: E402

plan, base, bl, kit, look, rs = db.plan, db.base, db.bl, db.kit, db.look, db.rs
Mesh, Glows, band, circle, face = db.Mesh, db.Glows, db.band, db.circle, db.face
STONE, PALE, PLATE, WARM, GLOWS = db.STONE, db.PALE, db.PLATE, db.WARM, db.GLOWS
FPS = 24
ZC = 0.6 + 5.0  # the front ring's middle, over the step

# A ring behind the front one: how far back, its radius, its turn (degrees a second, + anticlockwise seen from the way in),
# and its three arcs (start, end in degrees).
RINGS = {
    "five": ((1.7, 5.3, 9.0, (20, 135, 150, 262, 280, 350)),
             (3.0, 4.4, -14.0, (70, 170, 190, 300, 318, 410)),
             (4.1, 3.6, 20.0, (-30, 95, 112, 200, 222, 316)),
             (5.0, 2.9, -28.0, (40, 150, 168, 280, 296, 388))),
    "three": ((2.0, 5.0, 10.0, (20, 135, 152, 262, 282, 350)),
              (3.9, 3.7, -18.0, (-30, 95, 114, 200, 224, 316))),
}
DISC_Y = {"five": 5.9, "three": 5.0}


def front():
    """What stands still: the step, the front ring with its line, the name's plate on its crown, the disc."""
    m, g = Mesh(), Glows()
    m.box((14.0, 4.0, 0.6), (0, -0.6, 0.3), STONE, ink=True)
    band(m, circle(6.4, (0, ZC)), circle(5.0, (0, ZC)), -1.0, 0.6, STONE, (0, ZC), closed=True)
    g["line"].tube([(x, -1.08, z) for x, z in circle(5.12, (0, ZC))] + [(5.12, -1.08, ZC)], 0.1, PALE)
    m.box((5.0, 0.5, 1.3), (0, -1.15, ZC + 6.4 + 0.3), PLATE, ink=True)   # sunk into the crown, not floating
    return m, g


def ring(r, arcs):
    """One ring behind, built round its own middle so it turns there: a thin stone back, and a line of light along its
    inner edge, in three arcs."""
    m, g = Mesh(), Glows()
    for a0, a1 in zip(arcs[0::2], arcs[1::2]):
        band(m, circle(r, (0, 0), 44, a0, a1), circle(r - 0.32, (0, 0), 44, a0, a1), 0.0, 0.3, STONE, (0, 0),
             closed=False)
        g["line"].tube([(x, -0.06, z) for x, z in circle(r - 0.26, (0, 0), 44, a0 + 2, a1 - 2)], 0.08, PALE)
    return m, g


def disc(take, k):
    g = Glows()
    centre = (0.25 * k, ZC + 0.35 * k)
    face(g["disc"], [(x, DISC_Y[take], z) for x, z in circle(2.4 if take == "five" else 2.8, centre, 32)], PALE, (0, -1, 0))
    return g


def lit(g, name):
    return {key: part.whole().to_object(f"{name}{key}", look.glowing(f"{name}{key}", *GLOWS[key]))
            for key, part in g.items()}


def build(take, anchor, material, scene, yard):
    """The take under `anchor` (the Door's place and turn): the still parts, and each ring as its own object at its
    middle, returned with its rate. Everything made is returned too, to be removed."""
    made, turning = [], []

    def child(name, data, at=(0.0, 0.0, 0.0)):
        o = bpy.data.objects.new(name, data)
        o.parent, o.location = anchor, at
        scene.collection.objects.link(o)
        made.append(o)
        return o

    base.wear()
    m, g = front()
    child(f"Turn{take}Front", m.whole().to_object(f"Turn{take}Front", material))
    for key, data in lit(g, f"Turn{take}Front").items():
        child(f"Turn{take}Front{key}", data)
    rings = RINGS[take]
    for k, (y, r, rate, arcs) in enumerate(rings, start=1):
        m, g = ring(r, arcs)
        at = (0.25 * k, y, ZC + 0.35 * k)
        parts = [child(f"Turn{take}Ring{k}", m.whole().to_object(f"Turn{take}Ring{k}", material), at)]
        parts += [child(f"Turn{take}Ring{k}{key}", data, at) for key, data in lit(g, f"Turn{take}Ring{k}").items()]
        turning.append((parts, rate))
    for key, data in lit(disc(take, len(rings) + 1), f"Turn{take}Disc").items():
        child(f"Turn{take}Disc{key}", data)
    turn = Matrix.Rotation(anchor.rotation_euler.z, 3, "Z")
    for i, (at, watts, reach) in enumerate((((0.6, 3.0, ZC + 0.8), 36.0, 30.0), ((0, -4.0, 2.5), 12.0, 14.0),
                                            ((0, -1.8, 0.5), 10.0, 8.0))):   # inside; before it; the floor at the mouth
        lamp = look.light(yard.kit, scene, f"Turn{take}Lamp{i}", tuple(anchor.location + turn @ Vector(at)), WARM,
                          watts * kit.REAL_LIGHT, reach)
        lamp.data.use_shadow = False
        made.append(lamp)
    return made, turning


def shoot(scene, d, path):
    linear = look.render_linear(scene, path.with_suffix(".exr"))
    px = look.finish(linear, d)
    path.with_suffix(".exr").unlink(missing_ok=True)
    return px


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    fast = "fast" in args
    seconds = next((float(a) for a in args if a.replace(".", "", 1).isdigit()), 6.0)
    scene, yard, d = db.scene_up(fast)
    doors = [o for o in yard.kit.pieces if o.name.startswith("Door_")]
    print("the Door's pieces:", [(o.name, tuple(round(v, 2) for v in o.location)) for o in doors])
    for o in yard.kit.pieces:
        if o.name.startswith(("Door_", "DoorWay_")):
            o.hide_render = True
    anchor = bpy.data.objects.new("DoorAnchor", None)
    anchor.location, anchor.rotation_euler = doors[0].location.copy(), doors[0].rotation_euler.copy()
    scene.collection.objects.link(anchor)
    dx, dy = plan.DOOR[0], -plan.DOOR[1]
    yard.person((dx + 20.0, dy), "WayIn")
    views = {"way": db.player_view((dx + 20.0, dy), (dx, dy)),
             "home": plan.behind((plan.SPAWN[0], -plan.SPAWN[1]), -1),
             "side": ((dx + 20.0, dy + 9.0, 6.0), (dx, dy, 6.6))}
    material = yard.stock.mats["Kit"]
    strip, stills = {}, {}
    for take in RINGS:
        made, turning = build(take, anchor, material, scene, yard)
        for name in ("home", "side"):
            scene.camera = plan.camera(scene, f"{name}{take}", *views[name])
            stills[take, name] = shoot(scene, d, out / f"door_turn_{take}_{name}")
        scene.camera = plan.camera(scene, f"way{take}", *views["way"])
        frames = out / f"door_turn_{take}_frames"
        shutil.rmtree(frames, ignore_errors=True)
        frames.mkdir(parents=True)
        for f in range(round(seconds * FPS)):
            t = f / FPS
            for parts, rate in turning:
                for o in parts:
                    o.rotation_euler = (0.0, math.radians(-rate * t), 0.0)  # about the tunnel's axis
            px = shoot(scene, d, frames / f"{f:04d}")
            rs.save(px, frames / f"{f:04d}.png")
            if f % FPS == 0:
                strip[take, f // FPS] = px
        movie.assemble(frames, out / f"door_turn_{take}.mp4", FPS)
        shutil.rmtree(frames, ignore_errors=True)
        for o in made:
            bpy.data.objects.remove(o, do_unlink=True)
    rows = [np.concatenate([strip[take, s] for s in range(0, round(seconds), 2)], axis=1) for take in RINGS]
    rs.save(np.concatenate(rows, axis=0), out / "door_turn_strip.png")
    rows = [np.concatenate([stills[take, "home"], stills[take, "side"]], axis=1) for take in RINGS]
    rs.save(np.concatenate(rows, axis=0), out / "door_turn_stills.png")


if __name__ == "__main__":
    main()
