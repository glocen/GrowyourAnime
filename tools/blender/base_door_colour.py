"""AR15, section 7: the Festival Door's colour pass, on five (research's pick in motion, 2026-11-17), motion first again,
in its own light. The motion take's Door (base_door_turn.py), coloured: its stone the void machines' own (`abyss`),
so it belongs to the base; only its light is warm, the one warm light in a cold base, the festival's pull.

Two takes for research's verdict:
  A  warm all through: the mouth's line a deep amber, each ring behind paler, to a white-gold core. The eye runs
     from the saturated mouth to the pale light it comes from.
  B  void to warm: the mouth's line the base's violet, the rings behind passing through a pale white into gold, the
     core gold. From the base's void into the festival's warmth.
The lights are counted as the motion take's: one inside, one before it in the mouth's colour, one on the floor at
the mouth, past the step and stronger than the motion take's (10 W, reach 8, inside the step), so it holds against the flood mast's white pool beside it. The lines stay coloured, never burnt white: each glow is held low enough that its hue survives.

    blender -b --factory-startup --python tools/blender/base_door_colour.py -- <out> [seconds] [fast] [takes...]

Writes door_colour_<take>.mp4 (the way in, 24 a second), door_colour_strip.png (each take at the way in, every two
seconds) and door_colour_stills.png (each take from the spawn and three-quarter on).
"""
import math
import shutil
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_door_turn as dt  # noqa: E402

db, plan, base, kit, look, rs, movie = dt.db, dt.plan, dt.base, dt.kit, dt.look, dt.rs, dt.movie
FPS, ZC = dt.FPS, dt.ZC
STONE = "abyss"   # the void machines' stone (base_kit.SWATCHES)

# Each take: the front ring's line, the four rings' lines from the front back, the disc, each (colour, strength);
# then the three lights' colours: inside, before it, the floor at the mouth.
TAKES = {
    "A": dict(front=("#FF9038", 1.25),
              rings=(("#FFA448", 1.25), ("#FFB65C", 1.3), ("#FFC977", 1.35), ("#FFDA98", 1.4)),
              disc=("#FFDDA4", 1.05),
              lights=("#FFC27A", "#FFA858", "#FFC27A")),
    "B": dict(front=("#A97CFF", 1.3),
              rings=(("#C9B2FF", 1.25), ("#F2E8F4", 1.15), ("#FFDDA2", 1.3), ("#FFC56E", 1.35)),
              disc=("#FFCB7A", 1.1),
              lights=("#FFC98E", "#B98CFF", "#FFC98E")),
}


def lit(g, name, colour):
    """Every lit part of `g` in one colour and strength."""
    return [part.whole().to_object(f"{name}{key}", look.glowing(f"{name}{key}", *colour)) for key, part in g.items()]


def build(take, anchor, material, scene, yard):
    """dt.build, coloured: the still parts and each ring as its own object at its middle, with its rate."""
    paint, made, turning = TAKES[take], [], []

    def child(name, data, at=(0.0, 0.0, 0.0)):
        o = bpy.data.objects.new(name, data)
        o.parent, o.location = anchor, at
        scene.collection.objects.link(o)
        made.append(o)
        return o

    base.wear()
    dt.STONE = STONE   # the motion take's builders read their stone from their own module
    m, g = dt.front()
    child(f"Col{take}Front", m.whole().to_object(f"Col{take}Front", material))
    for data in lit(g, f"Col{take}Front", paint["front"]):
        child(data.name, data)
    for k, ((y, r, rate, arcs), colour) in enumerate(zip(dt.RINGS["five"], paint["rings"]), start=1):
        m, g = dt.ring(r, arcs)
        at = (0.25 * k, y, ZC + 0.35 * k)
        parts = [child(f"Col{take}Ring{k}", m.whole().to_object(f"Col{take}Ring{k}", material), at)]
        parts += [child(data.name, data, at) for data in lit(g, f"Col{take}Ring{k}", colour)]
        turning.append((parts, rate))
    for data in lit(dt.disc("five", len(dt.RINGS["five"]) + 1), f"Col{take}Disc", paint["disc"]):
        child(data.name, data)
    turn = Matrix.Rotation(anchor.rotation_euler.z, 3, "Z")
    places = (((0.6, 3.0, ZC + 0.8), 36.0, 30.0), ((0, -4.0, 2.5), 12.0, 14.0), ((0, -3.6, 0.8), 40.0, 14.0))
    for i, ((at, watts, reach), colour) in enumerate(zip(places, paint["lights"])):
        lamp = look.light(yard.kit, scene, f"Col{take}Lamp{i}", tuple(anchor.location + turn @ Vector(at)), colour,
                          watts * kit.REAL_LIGHT, reach)
        lamp.data.use_shadow = False
        made.append(lamp)
    return made, turning


def main():
    out = Path(sys.argv[sys.argv.index("--") + 1]).resolve()
    out.mkdir(parents=True, exist_ok=True)
    args = sys.argv[sys.argv.index("--") + 2:]
    fast = "fast" in args
    seconds = next((float(a) for a in args if a.replace(".", "", 1).isdigit()), 6.0)
    takes = [a for a in args if a in TAKES] or list(TAKES)
    scene, yard, d = db.scene_up(fast)
    doors = [o for o in yard.kit.pieces if o.name.startswith("Door_")]
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
    for take in takes:
        made, turning = build(take, anchor, material, scene, yard)
        for name in ("home", "side"):
            scene.camera = plan.camera(scene, f"{name}{take}", *views[name])
            stills[take, name] = dt.shoot(scene, d, out / f"door_colour_{take}_{name}")
        scene.camera = plan.camera(scene, f"way{take}", *views["way"])
        frames = out / f"door_colour_{take}_frames"
        shutil.rmtree(frames, ignore_errors=True)
        frames.mkdir(parents=True)
        for f in range(round(seconds * FPS)):
            t = f / FPS
            for parts, rate in turning:
                for o in parts:
                    o.rotation_euler = (0.0, math.radians(-rate * t), 0.0)   # about the tunnel's axis
            px = dt.shoot(scene, d, frames / f"{f:04d}")
            rs.save(px, frames / f"{f:04d}.png")
            if f % (2 * FPS) == 0:
                strip[take, f // FPS] = px
        if seconds >= 1.0:
            movie.assemble(frames, out / f"door_colour_{take}.mp4", FPS)
        shutil.rmtree(frames, ignore_errors=True)
        for o in made:
            bpy.data.objects.remove(o, do_unlink=True)
    rows = [np.concatenate([strip[take, s] for s in sorted(s for t, s in strip if t == take)], axis=1) for take in takes]
    rs.save(np.concatenate(rows, axis=0), out / "door_colour_strip.png")
    rows = [np.concatenate([stills[take, "home"], stills[take, "side"]], axis=1) for take in takes]
    rs.save(np.concatenate(rows, axis=0), out / "door_colour_stills.png")


if __name__ == "__main__":
    main()
