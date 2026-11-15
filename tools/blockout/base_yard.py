"""The base as its handoff has it, seen with Blender and Studio closed: the plan's placements and machines in their own
meshes and pictures (build/handoff/Base), drawn by view.py from the player's camera.

py tools/blockout/base_yard.py <out_dir> [views]

  <out>/yard_<view>.png   `gate` walking in from the Strip, `court` from where the player arrives, `heart` near the
                          generator, `generator` close on it, `bay` toward a bay from the way in, `down` from above. Naming views draws those.

People are bone stand-ins. It is a look at the layout, the floor and the drawn edges, not the game's light.
"""
import json
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path.insert(0, str(HERE))
import noblender  # noqa: E402,F401  (Blender's modules stood in, tools/blender on the path)
import base_kit as base  # noqa: E402
import base_plan as plan  # noqa: E402
import parts as pt  # noqa: E402
import view  # noqa: E402

HANDOFF = REPO / "build" / "handoff" / "Base"
GLOW = 0.5            # the kit's glow strength, as this view's
LAMPS = {"spot": (1.3, 30.0), "point": (1.0, 22.0)}   # a real light's strength and reach here, by its kind


def scene(level=1, spin=25.0):
    made = view.Scene()
    pieces = json.loads((HANDOFF / "manifest.json").read_text(encoding="utf-8"))["pieces"]
    page, glow = base.atlas()
    pictures = {"Kit": made.picture(page, glow, base.MAPS["Kit"][1] * GLOW)}
    for name, draw in base.FLOORS.items():
        colour, lit = draw()
        pictures[name] = made.picture(colour, lit, base.MAPS[name][1])
    records = {}

    def stand(name, at, turn, spin=0.0):
        if name not in records:
            records[name] = json.loads((HANDOFF / pieces[name]["mesh"]).read_text())
        worn = Path(pieces[name]["colour"]).stem.split("_")[1]
        made.mesh(records[name], pictures[worn], at, turn, spin=spin)

    places, lights = plan.plan(level)
    for name, x, along, turn in places:
        stand(name, (x, along, 0.0), turn)
    for name, x, inward, up, turn, _ in plan.machines(level):
        stand(name, (x, -inward, up), turn, spin if name == "GeneratorRotor" else 0.0)
    flat = pt.Parts()
    flat.block("Ground", 900, 700, 0.4, (0, -100, -0.5), plan.GROUND["ground"], "ground")
    flat.block("Strip", 700, base.STRIP, 0.4, (0, base.STRIP / 2, -0.3), "#4E4A66", "ground")
    flat.block("Lot", base.PLOT, base.PLOT, 0.4, (0, -base.PLOT / 2, -0.25), "#3C4160", "ground")
    flat.figure("Trainee", (plan.TRAINING[0], -(plan.TRAINING[1] - base.machines.TRAINEE), 0.56))
    for x, inward in plan.BAY_LOTS[:base.BAYS_AT[level]]:
        flat.figure("Worker", (x, -inward, 0.3))
    flat.figure("Shown", (plan.SHOWCASE[0], -plan.SHOWCASE[1], base.show.TOP))
    lamps = [dict(at=(x, along, up), colour=colour, power=LAMPS[kind][0], reach=LAMPS[kind][1])
             for _, x, along, up, colour, kind in lights]
    return made, flat, lamps


VIEWS = {"gate": ("player", (0.0, 9.0)), "court": ("player", (plan.SPAWN[0], -plan.SPAWN[1])),
         "heart": ("player", (0.0, -(base.ROW - 34.0))),
         "bay": ("eye", (-(base.OUTER - 38.0), -(base.ROW - 22.0), 7.0), (-base.OUTER, -base.ROW, 3.5)),
         "generator": ("eye", (7.0, -(base.ROW - 12.0), 7.5), (0.0, -base.ROW, 4.8)),
         "down": ("eye", (0.0, 60.0, 120.0), (0.0, -(base.ROW + 12.0), 0.0))}


def main():
    out = Path(sys.argv[1])
    names = sys.argv[2:] or list(VIEWS)
    made, flat, lamps = scene()
    for name in names:
        kind, *where = VIEWS[name]
        people = pt.Parts()
        people.parts = list(flat.parts)
        if kind == "player":
            people.figure("Player", (*where[0], 0.1))
            eye, target = view.behind(*where[0])
        else:
            eye, target = where
        drawn = view.Scene()
        drawn.p, drawn.uv, drawn.tex, drawn.colour, drawn.glow, drawn.cull = (list(v) for v in (made.p, made.uv, made.tex, made.colour, made.glow, made.cull))
        drawn.pictures = made.pictures
        drawn.parts(people.parts)
        view.save(view.draw(drawn, lamps, eye, target, haze=0.6 if name == "down" else 1.0), out / f"yard_{name}.png")
        print(f"yard_{name}.png")


if __name__ == "__main__":
    main()
