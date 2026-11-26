"""AR54: the yard's plan at Stage III, and its measure (docs/asset-requests.md, AR54). No Blender.

The plan at 128 was laid on Stage I's footprints. At Stage III the machines are wider and taller, and the plan breaks
(TR51's Studio run). PLAN is the plan laid again: every machine's spot, held at its Stage III footprint by part 7's
tests and by what the gate's eye sees.

    py tools/blender/base_fit.py                        the measure: Rules.BaseFit's tests on each stage's footprints
    py tools/blender/base_fit.py seen                   and what the gate sees of each machine, at each level
    py tools/blender/base_fit.py prints                 and each stage's footprints, as Config.World.Fit.Prints holds one

How it measures:
  a footprint   a machine's own pieces at a stage (the handoff's meshes, stood by plan.json's stage tables), as their
                box in the plot's axes about the machine's spot: `prints(stage)` is Config.World.Fit.Prints' table
  the tests     Rules.BaseFit's, line for line as base_plan.fit takes them, with the numbers of Config.World.Fit: the
                Breaker's walk, the least gap between two footprints, the way in, the square's edge, the gate's view
  the ring      the widest ring round the generator's spot that touches no other footprint
  seen          the machines' own meshes in a depth buffer through a gate's eye, at the smallest phone's pixels: the
                share of each machine's pixels, and of its top third's, that nothing nearer covers. Two eyes: the
                builder's held eye of TR51's captures (10 up, 11.5 before the gate's line, level), and the game's
                camera at its start zoom behind a player on the gate's line (20 degrees down)

The spots, across and inward from the gate's middle, and the turn. Why each stands there is AR54's record.
"""
import json
import math
import re
import sys
from pathlib import Path

import numpy as np

REPO = Path(__file__).resolve().parents[2]
HAND = REPO / "build" / "handoff" / "Base"
WORLD = REPO / "src" / "shared" / "Config" / "World.luau"
PLOT = 128.0
SIZE, FOV, PITCH, ZOOM, FOCUS = (852, 480), 70.0, 20.0, 12.5, 1.5   # the smallest phone; lantern_row_look's camera
HELD = (10.0, 11.5)                                                 # TR51's captures: the eye's height, and how far before the gate
PITCH_OF_POINTS = 0.35                                              # a mesh as points this far apart, for the gate's eye

# name: across, inward, turn. Bays 1 and 2 are level 1's, 3 at level 2, 4 at level 3; 5 and 6 stay locked at launch.
# Laid to research's order (AR54's pick, 2026-11-23): what the player touches stands where the game's camera at the gate
# sees it. The Door's side has four open spots for a full machine: bays 1 and 2, the Training machine and the Forge.
# Its fifth, behind the Door's ring, holds sleeping bay 6. The Condenser stands at the back, in the gap between the
# generator and the Breaker; bays 3 and 4 stand outside and behind the Breaker, their tops over its arm; the battery
# and the Lab's stone stand behind it.
PLAN = dict(
    generator=(0.0, 56.8, 0.0), breaker=(20.5, 30.5, 0.0), door=(-30.6, 24.4, 90.0),
    bay1=(-33.2, 59.2, 0.0), bay2=(-30.3, 90.9, 0.0), training=(-55.1, 76.4, 0.0), forge=(-53.4, 99.3, 0.0),
    bay6=(-54.6, 42.3, 0.0),
    condenser=(25.5, 99.0, 0.0), bay3=(51.1, 73.6, 180.0), bay4=(49.7, 97.6, 180.0), battery=(56.7, 44.9, 0.0),
    lab=(32.7, 51.6, 0.0), bay5=(-0.7, 95.6, 0.0))
TOUCHED = {1: ("breaker", "door", "bay1", "bay2", "forge", "training", "condenser", "battery"),
           2: ("breaker", "door", "bay1", "bay2", "forge", "training", "condenser", "bay3", "battery"),
           3: ("breaker", "door", "bay1", "bay2", "forge", "training", "condenser", "bay3", "bay4", "battery")}

_plan = json.loads((HAND / "plan.json").read_text(encoding="utf-8"))["machines"]
_mesh, _cloud = {}, {}


def mesh(name):
    if name not in _mesh:
        m = json.loads((HAND / "meshes" / f"{name}.json").read_text())
        _mesh[name] = (np.array(m["p"], float).reshape(-1, 3) + np.array(m["c"], float),
                       np.array(m["f"], int).reshape(-1, 9)[:, :3])
    return _mesh[name]


def turn_y(degrees):
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])


def kind_of(name):
    return "bay" if name.startswith("bay") else name


def rows(kind, stage):
    """A machine's pieces at a stage, each with its place in the machine's own frame: across, toward the gate, up."""
    s = str(stage)
    if kind == "generator":
        return [(r["piece"], (r["across"], r["along"] - _plan["generatorStages"]["stages"]["1"][0]["along"], r["up"]))
                for r in _plan["generatorStages"]["stages"][s]]
    if kind in ("breaker", "bay", "battery", "training"):
        table = _plan[kind + "Stages"]["stages"][s]
        return [(r["piece"], tuple(r["at"])) for r in (table["pieces"] if isinstance(table, dict) else table)]
    if kind in ("forge", "condenser"):
        return [(_plan[kind + "Stages"]["stages"][s]["frame"], (0.0, 0.0, 0.0))]
    if kind == "door":
        home = next(r for r in _plan["placements"] if r["piece"] == "Door")
        made = []
        for r in _plan["placements"]:
            if r["piece"].startswith("Door"):
                v = np.array([r["across"] - home["across"], 0.0, -(r["along"] - home["along"])]) @ turn_y(home["turn"])
                made.append((r["piece"], (float(v[0]), float(-v[2]), r["up"])))
        return made
    return [({"lab": "SleepingStone", "asleep": "BaySleeping"}[kind], (0.0, 0.0, 0.0))]


def shown(name, level):
    """What stands at a machine's spot at a base's level, every machine at that level's stage: its kind and stage.
    Bays 5 and 6 sleep at every level, bays 3 and 4 at level 1, and the Lab is its stone."""
    kind = kind_of(name)
    if kind == "bay" and (int(name[3:]) > 4 or (level == 1 and int(name[3:]) > 2)):
        return "asleep", 1
    return kind, (1 if kind in ("door", "lab") else level)


def triangles(kind, stage, turn):
    made = []
    for piece, at in rows(kind, stage):
        v, f = mesh(piece)
        made.append(((v + np.array([at[0], at[2], -at[1]])) @ turn_y(turn).T)[f])
    return np.concatenate(made)                                     # x across, y up, z inward, about the spot


def footprint(kind, stage, turn=0.0):
    """A footprint as Config.World.Fit.Prints holds one: its middle's offset from its spot, its size, its height."""
    p = triangles(kind, stage, turn).reshape(-1, 3)
    lo, hi = p.min(0), p.max(0)
    return dict(Across=round(float(lo[0] + hi[0]) / 2, 2), Inward=round(float(lo[2] + hi[2]) / 2, 2),
                Wide=round(float(hi[0] - lo[0]), 2), Deep=round(float(hi[2] - lo[2]), 2), High=round(float(hi[1]), 2))


def prints(stage):
    """Every kind's footprint at a stage, as the plan turns it. A bay's is the same at either turn, mirrored."""
    return {kind: footprint(kind, 1 if kind in ("door", "lab", "asleep") else stage, 90.0 if kind == "door" else 0.0)
            for kind in ("generator", "breaker", "door", "bay", "battery", "training", "forge", "condenser", "lab", "asleep")}


def fit_numbers():
    """Part 7's numbers as the game has them (Config.World.Fit, the kept back and the walk)."""
    text = WORLD.read_text(encoding="utf-8")
    block = text[text.index("\tFit = {"):]
    block = block[:block.index("\n\t},")]   # to the block's own close
    num = lambda key: float(re.search(rf"\b{key} = ([\d.]+)", block).group(1))   # noqa: E731
    cam = re.search(r"Camera = \{ Back = ([\d.]+), Fov = ([\d.]+), Aspect = (\d+) / (\d+) \}", block)
    walk = float(re.search(r"\bWalk = (\d+)", text).group(1))
    return dict(Breaker=num("Breaker"), Clear=num("Clear"), Avenue=num("Avenue"), Apron=num("Apron"), Margin=num("Margin"),
                Back=float(cam.group(1)), Fov=float(cam.group(2)), Aspect=float(cam.group(3)) / float(cam.group(4)),
                Kept=float(re.search(r"\bKept = ([\d.]+)", text).group(1)) * walk, Walk=walk)


def boxes(plan, stage):
    """Each machine's footprint where it stands: across from, across to, inward from, inward to, and its height. A
    sleeping bay is held to a bay's footprint, since it wakes into one."""
    made = {}
    for name, (x, z, turn) in plan.items():
        kind = kind_of(name)
        p = footprint(kind, 1 if kind in ("door", "lab") else stage, turn)
        cx, cz = x + p["Across"], z + p["Inward"]
        made[name] = (cx - p["Wide"] / 2, cx + p["Wide"] / 2, cz - p["Deep"] / 2, cz + p["Deep"] / 2, p["High"])
    return made


def measure(plan, stage=3):
    """Rules.BaseFit's measures of a plan with every machine at a stage's footprint, and the generator's own ring."""
    f, b = fit_numbers(), boxes(plan, stage)

    def gap(a, c):
        dx = max(0.0, max(a[0], c[0]) - min(a[1], c[1]))
        dz = max(0.0, max(a[2], c[2]) - min(a[3], c[3]))
        return math.hypot(dx, dz) if dx > 0 or dz > 0 else -min(a[1] - c[0], c[1] - a[0], a[3] - c[2], c[3] - a[2])

    names = sorted(b)
    pairs = sorted((gap(b[a], b[c]), a, c) for i, a in enumerate(names) for c in names[i + 1:])
    g, half = b["generator"], PLOT / 2 - f["Margin"]
    way = [n for n, k in b.items() if n != "generator" and k[2] < g[2] and k[0] < f["Avenue"] / 2 and k[1] > -f["Avenue"] / 2]
    outside = [n for n, k in b.items() if k[0] < -half or k[1] > half or k[2] < f["Apron"] or k[3] > PLOT - f["Kept"]]
    view = max((math.degrees(math.atan2(abs(x), z + f["Back"])), n) for n, k in b.items() for x in k[:2] for z in k[2:4])
    k = b["breaker"]
    seconds = math.hypot(min(max(0.0, k[0]), k[1]), min(max(0.0, k[2]), k[3])) / f["Walk"]
    half_view = math.degrees(math.atan(math.tan(math.radians(f["Fov"] / 2)) * f["Aspect"]))
    gx, gz, _ = plan["generator"]
    ring = min((math.hypot(max(k[0] - gx, gx - k[1], 0.0), max(k[2] - gz, gz - k[3], 0.0)), n)
               for n, k in b.items() if n != "generator")
    return dict(stage=stage, breaker=round(seconds, 2), least=[(round(d, 2), a, c) for d, a, c in pairs[:5]], way=way,
                outside=outside, widest=(round(view[0], 2), view[1]), halfView=round(half_view, 2),
                ring=(round(ring[0], 1), ring[1]), boxes=b,
                passes=(seconds <= f["Breaker"] and pairs[0][0] >= f["Clear"] and not way and not outside
                        and view[0] <= half_view))


def cloud(kind, stage, turn):
    key = (kind, stage, turn)
    if key not in _cloud:
        t = triangles(kind, stage, turn)
        a, b, c = t[:, 0], t[:, 1], t[:, 2]
        cuts = np.ceil(np.maximum.reduce([np.linalg.norm(b - a, axis=1), np.linalg.norm(c - b, axis=1),
                                          np.linalg.norm(a - c, axis=1)]) / PITCH_OF_POINTS).astype(int).clip(1, 60)
        pts = []
        for n in sorted(set(cuts)):
            pick = cuts == n
            for i in range(n + 1):
                for j in range(n + 1 - i):
                    pts.append(a[pick] * (1 - (i + j) / n) + b[pick] * (i / n) + c[pick] * (j / n))
        _cloud[key] = np.unique(np.concatenate(pts).round(2), axis=0)
    return _cloud[key]


def gate_eye(eye="player"):
    """A gate's eye: where it is, and its forward, right and up. "player" is the game's camera at its start zoom behind
    a player on the gate's line, 20 degrees down: the measure (research's pick, AR54). "held" is the builder's own for
    TR51's captures, 10 up and 11.5 before the gate's line, looking level, kept to compare with them."""
    if eye == "held":
        return (np.array([0.0, HELD[0], -HELD[1]]), np.array([0.0, 0.0, 1.0]), np.array([1.0, 0.0, 0.0]),
                np.array([0.0, 1.0, 0.0]))
    pitch = math.radians(PITCH)
    at = np.array([0.0, 3.0 + FOCUS + math.sin(pitch) * ZOOM, -math.cos(pitch) * ZOOM])
    return (at, np.array([0.0, -math.sin(pitch), math.cos(pitch)]), np.array([1.0, 0.0, 0.0]),
            np.array([0.0, math.cos(pitch), math.sin(pitch)]))


def seen(plan, level, eye="player"):
    """What a gate's eye sees at a base's level: name -> (the share of its pixels seen, of its top third's), and the
    picture's owner at each pixel."""
    eye, fwd, right, up = gate_eye(eye)
    f = SIZE[1] / 2 / math.tan(math.radians(FOV / 2))
    count = SIZE[0] * SIZE[1]
    depth, owner, own = np.full(count, np.inf), np.full(count, -1), []
    for index, (name, (x, z, turn)) in enumerate(plan.items()):
        pts = cloud(*shown(name, level), turn) + np.array([x, 0.0, z])
        v = pts - eye
        d = v @ fwd
        keep = d > 1.0
        v, d, top = v[keep], d[keep], (pts[:, 1] > pts[:, 1].max() * 2 / 3)[keep]
        px, py = SIZE[0] / 2 + f * (v @ right) / d, SIZE[1] / 2 - f * (v @ up) / d
        size = np.clip(np.ceil(PITCH_OF_POINTS * f / d).astype(int) + 1, 1, 12)
        whole, tops = np.full(count, np.inf), np.full(count, np.inf)
        for s in np.unique(size):
            pick = size == s
            for ox in range(s):
                for oy in range(s):
                    ix, iy = (px[pick] + ox - s / 2).round().astype(int), (py[pick] + oy - s / 2).round().astype(int)
                    ok = (ix >= 0) & (ix < SIZE[0]) & (iy >= 0) & (iy < SIZE[1])
                    flat = iy[ok] * SIZE[0] + ix[ok]
                    np.minimum.at(whole, flat, d[pick][ok])
                    np.minimum.at(tops, flat[top[pick][ok]], d[pick][ok][top[pick][ok]])
        own.append((whole, tops))
        nearer = whole < depth
        depth[nearer], owner[nearer] = whole[nearer], index
    shares = {}
    for index, name in enumerate(plan):
        whole, tops = own[index]
        mine, top = np.isfinite(whole), np.isfinite(tops) & (tops <= whole + 0.3)
        shares[name] = (float(((owner == index) & mine).sum()) / max(int(mine.sum()), 1),
                        float(((owner == index) & top).sum()) / max(int(top.sum()), 1))
    return shares, owner.reshape(SIZE[1], SIZE[0])


def main():
    args = sys.argv[1:]
    name, plan = "AR54's plan", PLAN
    for stage in (1, 2, 3):
        m = measure(plan, stage)
        print(f"{name}, Stage {'I' * stage}'s footprints: {'PASS' if m['passes'] else 'FAIL'}. The Breaker {m['breaker']} s "
              f"from the gate; the widest corner {m['widest'][0]} degrees ({m['widest'][1]}) of {m['halfView']}; on the "
              f"way in {m['way'] or 'nothing'}; outside {m['outside'] or 'nothing'}; the generator's ring {m['ring'][0]} "
              f"(to {m['ring'][1]})")
        print("  the least gaps: " + "; ".join(f"{d} {a} to {c}" for d, a, c in m["least"]))
    if "prints" in args:
        for stage in (1, 2, 3):
            print(f"Stage {'I' * stage}: " + json.dumps(prints(stage)))
    if "seen" in args:
        for eye, what in (("player", "the game's camera behind a player on the line"), ("held", "TR51's held eye")):
            for level in (1, 2, 3):
                shares, _ = seen(plan, level, eye)
                print(f"from the gate, {what}, level {level}, every machine at Stage {'I' * level}: " + ", ".join(
                    f"{n} {round(100 * shares[n][0])}% (its top {round(100 * shares[n][1])}%)" for n in TOUCHED[level]))


if __name__ == "__main__":
    main()
