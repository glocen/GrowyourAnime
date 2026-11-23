"""AR50's audit (docs/asset-requests.md, AR50, "The rings' refit"): the rings afloat as exported, stood by the plan's
own rows, measured over their whole turn against everything that stands on a plot at base levels 2 and 3, and through
the game's camera at the review's four stands. No Blender: it reads build/handoff/Base (plan.json and the meshes).

    py tools/blender/base_levels_clear.py [handoff folder]

The bar (research, 2026-11-23): each ring clears the generator's Stages II and III by 1.2 over a full turn, level 2's
stands whole in the frame from the gate's line, and both are in the frame from the Strip. It exits 1 when a gap is
under LEAST or level 2's ring leaves the gate-line frame.

How it measures, in Roblox's frame with the plot's heart at the origin (x across, y up, z into the plot):
  a ring       its exported mesh as points no more than PITCH apart on every face, posed as the plan's note says
               (lean, then tilt, then its turn), every STEP degrees through a half turn (its lengths repeat by then)
  the generator  the stage of each level (II at 2, III at 3): its still pieces as points; its wheel and its demand's mark
               as their sweep about the axle (radius, depth), since they turn too
  the rest     every other piece by its box where it stands: the gate, the pylons and their spans, the flood masts,
               the transformers, the Door, the fins, and each machine at its last stage on every bay that can be awake
A gap is point to point (or point to box), so it can read up to about PITCH over the truth: LEAST is held with that
in hand.
"""
import json
import math
import sys
from pathlib import Path

import numpy as np
from scipy.spatial import cKDTree

LEAST, PITCH, STEP = 1.2, 0.6, 3
ROW, AXLE_UP = 52.0, 10.0                      # the heart's line in from the front edge; the wheel's axle over the deck
SIZE, FOV, PITCH_DOWN, ZOOM, FOCUS = (852, 480), 70.0, 20.0, 12.5, 4.5   # the smallest phone; the game's camera at its
# start zoom behind a player (lantern_row_look's numbers), the same four stands as base_levels_block.py: (across, out of
# the front edge), then where the player looks
STANDS = {"the gate's line": ((0.0, 1.0), (0.0, -ROW)), "facing the gate": ((0.0, 24.0), (0.0, 0.0)),
          "the Strip, 90": ((-90.0, 24.0), (0.0, 24.0)), "the Strip, 150": ((-150.0, 24.0), (0.0, 24.0))}
OTHERS = ("Pylon", "PowerSpan", "FloodMast", "Transformer", "Showcase", "Gate1")
STAGED = {"breakerStages": "Breaker", "bayStages": "Bay", "batteryStages": "BatteryRack", "trainingStages": "Training"}


class Handoff:
    def __init__(self, folder):
        self.folder = Path(folder)
        self.plan = json.loads((self.folder / "plan.json").read_text(encoding="utf-8"))
        self.machines = self.plan["machines"]

    def mesh(self, name):
        m = json.loads((self.folder / "meshes" / f"{name}.json").read_text())
        return (np.array(m["p"], float).reshape(-1, 3) + np.array(m["c"], float),
                np.array(m["f"], int).reshape(-1, 9)[:, :3])

    def cloud(self, name):
        """A piece as points no more than PITCH apart on every face."""
        v, f = self.mesh(name)
        a, b, c = v[f[:, 0]], v[f[:, 1]], v[f[:, 2]]
        cuts = np.ceil(np.maximum.reduce([np.linalg.norm(b - a, axis=1), np.linalg.norm(c - b, axis=1),
                                          np.linalg.norm(a - c, axis=1)]) / PITCH).astype(int)
        pts = [v]
        for n in sorted(set(cuts[cuts > 1])):
            pick = cuts == n
            for i in range(n + 1):
                for j in range(n + 1 - i):
                    pts.append(a[pick] * (1 - (i + j) / n) + b[pick] * (i / n) + c[pick] * (j / n))
        return np.unique(np.concatenate(pts).round(3), axis=0)

    def box(self, name, across, along, up=0.0, turn=0.0, at=(0.0, 0.0, 0.0)):
        """A piece's box where it stands; `at` is a stage row's place in its machine's own frame (across, toward the
        gate, up), turned with the machine."""
        v, _ = self.mesh(name)
        w = (v + np.array([at[0], at[2], -at[1]])) @ turn_y(turn).T + np.array([across, up, -along - ROW])
        return name, w.min(0), w.max(0)

    def stage(self, table, stage):
        rows = self.machines[table]["stages"][str(stage)]
        return rows["pieces"] if isinstance(rows, dict) else rows

    def world(self, level):
        """What stands on a plot at a base's level: the generator's still points, its turning parts' sweep, the rest's boxes."""
        still, swept, boxes = [], [], []
        for row in self.stage("generatorStages", level):
            place = np.array([row["across"], row["up"], -row["along"] - ROW])
            if row["moves"] in ("turns", "demand") and row["across"] == 0.0:
                v = self.cloud(row["piece"]) + place
                swept.append(np.stack([np.hypot(v[:, 0], v[:, 1] - AXLE_UP), v[:, 2]], axis=1))
            else:
                still.append(self.cloud(row["piece"]) + place)
        for row in self.plan["levels"]["1"]["placements"]:
            if row["piece"] in OTHERS:
                boxes.append(self.box(row["piece"], row["across"], row["along"], 0.0, row["turn"]))
        homes = {}
        for row in self.machines["placements"]:
            homes.setdefault(row["piece"], []).append(row)
            if row["piece"].startswith(("Door", "BayHalo")):
                boxes.append(self.box(row["piece"], row["across"], row["along"], row["up"], row["turn"]))
        for table, body in STAGED.items():
            places = homes[body] + (homes["BaySleeping"][:2] if body == "Bay" else [])   # bays 3 and 4 wake by level 3
            for home in places:
                for row in self.stage(table, 3):
                    boxes.append(self.box(row["piece"], home["across"], home["along"], 0.0, home["turn"], row["at"]))
        for at_level in range(2, level + 1):
            for row in self.machines["baseLevels"]["levels"][str(at_level)]["pieces"]:
                if row["moves"] == "still" and row["up"] == 0.0 and "Fin" in row["piece"]:
                    boxes.append(self.box(row["piece"], row["across"], row["along"]))
        still = np.concatenate(still)
        return (cKDTree(still[still[:, 1] > 3.0]), cKDTree(np.concatenate(swept)), [b[0] for b in boxes],
                np.array([b[1] for b in boxes]), np.array([b[2] for b in boxes]))


def turn_y(degrees):
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])


def stood(tilt, lean, turned):
    """The plan's note: CFrame.Angles(0, 0, lean) * CFrame.Angles(tilt, 0, 0) * CFrame.Angles(0, angle * sign, 0)."""
    a, b = math.radians(tilt), math.radians(lean)
    rx = np.array([[1, 0, 0], [0, math.cos(a), -math.sin(a)], [0, math.sin(a), math.cos(a)]])
    rz = np.array([[math.cos(b), -math.sin(b), 0], [math.sin(b), math.cos(b), 0], [0, 0, 1]])
    return rz @ rx @ turn_y(turned)


def gaps(ring, still, swept, names, lows, highs):
    body = float(still.query(ring)[0].min())
    wheel = float(swept.query(np.stack([np.hypot(ring[:, 0], ring[:, 1] - AXLE_UP), ring[:, 2]], axis=1))[0].min())
    lo, hi = ring.min(0), ring.max(0)
    other, which = 99.0, "nothing near"
    for k in np.flatnonzero(np.all((lows < hi + 6.0) & (highs > lo - 6.0), axis=1)):
        d = float(np.linalg.norm(np.maximum(np.maximum(lows[k] - ring, ring - highs[k]), 0.0), axis=1).min())
        if d < other:
            other, which = d, names[k]
    return body, wheel, other, which


def framed(ring, at, toward):
    """The ring through the game's camera behind a player at `at` looking toward `toward`: left, right, top and bottom
    in the phone's pixels (the top at 0), and the share of it inside the frame."""
    pitch = math.radians(PITCH_DOWN)
    head = np.array([toward[0] - at[0], 0.0, -(toward[1] - at[1])])
    head /= np.linalg.norm(head)
    eye = np.array([at[0], FOCUS, -at[1] - ROW]) - head * math.cos(pitch) * ZOOM + np.array([0, math.sin(pitch) * ZOOM, 0])
    fwd = head * math.cos(pitch) - np.array([0, math.sin(pitch), 0])
    right = np.cross(fwd, [0, 1, 0])
    right /= np.linalg.norm(right)
    v = ring - eye
    depth, half = v @ fwd, SIZE[1] / 2 / math.tan(math.radians(FOV / 2))
    x, y = SIZE[0] / 2 + half * (v @ right) / depth, SIZE[1] / 2 - half * (v @ np.cross(right, fwd)) / depth
    return x.min(), x.max(), y.min(), y.max(), float(np.mean((x > 0) & (x < SIZE[0]) & (y > 0) & (y < SIZE[1]) & (depth > 0)))


def main():
    hand = Handoff(sys.argv[1] if len(sys.argv) > 1 else "build/handoff/Base")
    worlds = {level: hand.world(level) for level in (2, 3)}
    failed = False
    for level, entry in hand.machines["baseLevels"]["levels"].items():
        for row in entry["pieces"]:
            if row["moves"] != "turns":
                continue
            pts = hand.cloud(row["piece"])
            place = np.array([row["across"], row["up"], -row["along"] - ROW])
            worst, frames = {}, {stand: [9e9, -9e9, 9e9, -9e9, 1.0] for stand in STANDS}
            for turned in range(0, 180, STEP):
                ring = pts @ stood(row["tilt"], row["lean"], turned * row["sign"]).T + place
                for at_level in range(int(level), 4):
                    body, wheel, other, which = gaps(ring, *worlds[at_level])
                    for key, gap, name in ((f"level {at_level}, the generator's body", body, ""),
                                           (f"level {at_level}, its turning parts' sweep", wheel, ""),
                                           (f"level {at_level}, the nearest other piece", other, which)):
                        if gap < worst.get(key, (9e9, ""))[0]:
                            worst[key] = (gap, name)
                for stand, (at, toward) in STANDS.items():
                    seen, f = framed(ring, at, toward), frames[stand]
                    frames[stand] = [min(f[0], seen[0]), max(f[1], seen[1]), min(f[2], seen[2]), max(f[3], seen[3]),
                                     min(f[4], seen[4])]
            print(f"{row['piece']}: across {row['across']:g}, along {row['along']:g}, up {row['up']:g}, tilt {row['tilt']:g}, "
                  f"lean {row['lean']:g}; {len(pts)} points, every {STEP} degrees of a half turn")
            for key, (gap, name) in worst.items():
                under = gap < LEAST
                failed |= under
                print(f"  {key}: {gap:.2f} {name}" + ("   UNDER THE BAR" if under else ""))
            for stand, f in frames.items():
                print(f"  from {stand}: x {f[0]:.0f} to {f[1]:.0f}, y {f[2]:.0f} to {f[3]:.0f} of {SIZE[0]} by {SIZE[1]}; "
                      f"at least {f[4] * 100:.0f}% in the frame")
            if row["piece"] == "LevelRing" and frames["the gate's line"][4] < 1.0:
                failed = True
                print("  LevelRing leaves the frame from the gate's line   UNDER THE BAR")
    print("AR50's rings: " + ("FAIL" if failed else f"PASS, every gap at least {LEAST:g}"))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
