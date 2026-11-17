"""Pip's basic attack, its look as rows (AR26, Pip third; /ga-action steps 1 and 3; AR8, "The method").

py tools/blender/pip_combo_fx.py measure
py tools/blender/pip_combo_fx.py screen
py tools/blender/pip_combo_fx.py rows <out_dir>

Plain Python, no Blender. Its numbers come from the delivered clip (build/handoff/Pip/clips/Pip_Combo.json, the
Transforms the game plays) on the recipe's lamp joint on the Torso, and from the action's own row (read only:
src/shared/Definitions/Actions.luau, PipCombo's Beats, Range and Reach).
- measure: the lantern and the sleeve in his root's frame through the clip, with the lantern's speed.
- screen: where the lantern, the shot's path and the Shade land on a phone's screen from the game's camera.
"""
import itertools
import json
import math
import random
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kirra_scarf_step_fx as k  # noqa: E402  (the CFrame sums, the Track reader, the rows file check)
import watt_combo_fx as w  # noqa: E402  (the game's camera, the Shade's boxes, what it covers: AR26's first attack)
import rook_combo_fx as rk  # noqa: E402  (R6's shoulders)
import combo_targets as ct  # noqa: E402  (every target the pop lands on, and rule 4's guards against them)

ROOT = Path(__file__).resolve().parents[2]
RECIPE = ROOT / "build" / "handoff" / "Pip" / "Pip.recipe.json"
CLIP = ROOT / "build" / "handoff" / "Pip" / "clips" / "Pip_Combo.json"
ACTIONS = ROOT / "src" / "shared" / "Definitions" / "Actions.luau"  # read only
ACTION = "PipCombo"
HITS = {"Shot1": 10, "Shot2": 26, "Shot3": 62}  # the clip's markers, checked against it and against the action's Beats
ROOT_HEIGHT = 3.0  # R6: the HumanoidRootPart's centre over the floor
LAMP = "Pip_Lamp"
APPROACH = 1.0  # Config.Combat.Approach: a lead fights from its action's Range less this


def read_action():
    text = ACTIONS.read_text(encoding="utf-8")
    start = text.index(f'Id = "{ACTION}"')
    block = text[start:text.index("Id = ", start + 10)]
    beats = {n: round(float(v) * 60) for n, v in re.findall(r"(\w+) = ([\d.]+)", re.search(r"Beats = \{([^}]*)\}", block).group(1))}
    if beats != HITS:
        raise SystemExit(f"the action's beats moved: {beats}")
    return {"beats": beats, "range": float(re.search(r"\bRange = ([\d.]+)", block).group(1))}


def spacing():
    return read_action()["range"] - APPROACH


def measure(frames=None):
    """The lantern's middle and the sleeve's end in his root's frame (x right, y from the floor, z back)."""
    recipe = json.loads(RECIPE.read_text(encoding="utf-8"))
    clip = json.loads(CLIP.read_text(encoding="utf-8"))
    marks = {m["Name"]: round(m["T"] * clip["Fps"]) for m in clip["Markers"]}
    if marks != HITS:
        raise SystemExit(f"the clip's markers moved: {marks}")
    points = {p["name"]: p["at"] for p in recipe["points"]}
    lamp = next(p for p in recipe["pieces"] if p["name"] == LAMP)
    if lamp["on"] != "Torso":
        raise SystemExit("the lamp isn't on the Torso")
    out = {}
    for f in frames if frames is not None else range(len(clip["Frames"])):
        poses = clip["Frames"][f]["Poses"]
        torso = k.compose(k.compose(k.R6_ROOT, k.cframe(poses["Torso"])), k.inverse(k.R6_ROOT))
        joint = k.compose(k.compose(torso, k.moved(k.sub(lamp["pivot"], [0.0, ROOT_HEIGHT, 0.0]))), k.cframe(poses[LAMP]))
        lantern = k.add(k.compose(joint, k.moved(k.sub(points["Lantern"], lamp["pivot"])))[1], [0, ROOT_HEIGHT, 0])
        c0, c1 = rk.RIGHT_SHOULDER
        arm = k.compose(torso, k.compose(k.compose(c0, k.cframe(poses["Right Arm"])), k.inverse(c1)))
        sleeve = k.add(k.compose(arm, k.moved(k.sub(points["Sleeve"], rk.ARM_REST["Right Arm"])))[1], [0, ROOT_HEIGHT, 0])
        out[f] = {"Lantern": lantern, "Sleeve": sleeve}
    return out


HEADINGS = w.HEADINGS


def screen():
    ahead = spacing()
    n = measure(list(HITS.values()))
    boxes = w.shade_boxes(ahead)
    chest = [0.0, 3.0, -ahead]
    for h in HEADINGS:
        cam = w.camera(ahead, h)
        print(f"heading {h} (the Shade {ahead} ahead):")
        for hit, f in HITS.items():
            lantern = n[f]["Lantern"]
            path = [k.add(lantern, k.mul(k.sub(chest, lantern), i / 10)) for i in range(11)]
            cells = []
            for i, p in enumerate(path):
                s = w.on_screen(p, cam)
                cells.append(f"{i / 10:.1f}({s[0]:+.2f},{s[1]:+.2f}){'#' if w.covered(p, cam, boxes) else ''}")
            print(f"  {hit} lantern {k.v3(lantern)['Vector3']}: " + " ".join(cells))
    print("(the path from the lantern to the Shade's chest by tenths: screen shares from its middle; # covered)")


# --- the rows: the hero is the ember, from the lantern's spit to the pop -------------------------------------------
# Research's feel line (AR26, signed 08:06, its camera corrected 08:16): each flick throws a spitting ember that streaks
# into the Shade and pops in a small flame bloom; the third, the lantern kicked over, sends a fatter one with a short
# ribbon behind it. From across the street, a schoolboy's fireworks that still land. No area: the shot ends on its target.
# Measured (screen): the lantern spits beside his head on the beat (frames 10 and 26, and 62 as it starts to kick over),
# 13.5 studs from the Shade at his spacing, though a Shade walks in on him. At the main framing (215) the shot comes at
# the camera: the ember shows for the first 70% of its way, then the Shade covers it, and covers where it lands.
# Three parts, each where it can live:
# - PipShots (this action's rows, in his frame): on each beat the lantern spits, a few short lines, sparks dropping
#   away and a light, at the lantern's place on that frame. The builder's three Streaks stay until the ember flies.
# - The ember's flight: from the lantern to the target as it stands, so it can't be rows in his frame. It's Faber's:
#   AR26, "Pip's basic attack", the ask (a Streak that travels, then plays its pop, and lands the hit when it arrives).
# - PipPop (its own rows, played where the ember lands, facing its way): a small bloom of petals off the Shade's front,
#   three sparks flung out past its outline, a crackle of sparks and a light. The third's plays bigger.
# DESIGN seeds, tuned live.
GREY, SPARK = "fx_beam", "fx_spark"
WHITE = {"Color3": [255, 255, 255]}
USED = (GREY, SPARK)
MOUTH = 0.35  # studs from the lantern's middle toward the target: where the spit leaves it
SPIT = {  # per beat: lines, long and short, their rake round the aim, width; the light; the sparks let go
    "Shot1": {"lines": 4, "long": 0.85, "short": 0.55, "rake": 18, "width": 0.1, "light": (6, 3, 5), "sparks": 5},
    "Shot2": {"lines": 4, "long": 0.85, "short": 0.55, "rake": 18, "width": 0.1, "light": (6, 3, 5), "sparks": 5},
    "Shot3": {"lines": 5, "long": 1.2, "short": 0.8, "rake": 22, "width": 0.14, "light": (8, 5, 7), "sparks": 8},
}
SPIT_LIFE = (1, 2, 5)  # frames: out; held; gone
SPIT_AT = {"Shot1": 10, "Shot2": 26, "Shot3": 62}  # the clip's frame whose lantern place the spit stands at
PETALS = {"angles": (80, 115, 150, 210, 245, 280), "long": 1.0, "short": 0.65, "hollow": 0.2, "rake": 60, "width": 0.16,
          "life": (1.5, 3, 7)}  # the bloom: degrees round its face from up (+ to the right as the ember sees it). A long
#   petal passes the guards, jittered either way, from 75 to 150 each side: nearer up it meets the low masks (Support's
#   foot is 3.30 up, Dasher's 3.06), nearer down it runs toward the street. So it opens to the sides.
FLUNG = [(270, 2.8, 0.0), (90, 2.8, 0.6), (240, 1.6, 0.3)]  # the pop's sparks: degrees round its face from up (+ to the
#   right as the ember sees it), studs long, tipped back toward him. The Shade hides where the ember lands from both
#   framings, so the first two are flung out sideways past its arms: the first shows at 215 (0.9 studs), the second at
#   145 (1.2), the most of any way that passes the guards (up and out crosses a low mask from 28; down runs to the
#   street). The third, short and low, shows from his side.
FLUNG_WIDTH, FLUNG_LIFE = 0.07, (2, 3, 9)
DOWN_CLEAR = 45  # degrees: no flung spark aims within this of straight down (the content check, 2026-11-17: light run
#   from a struck belly to the street reads as a drip, in any colour)
FLOOR = 1.0  # studs up, about the knee: no pop line comes lower, at either spacing or size
CRACKLE = {"turns": (-55, 55), "spread": 15, "speed": (2.5, 5), "drag": 8, "life": (0.15, 0.3), "fall": 4, "count": 5}
#   the pop's crackle, in the air: two sprays thrown back toward him and out to each side, turned off straight back by
#   `turns` about up, slowed hard (Drag: speed halves every 1/drag s), barely falling, shrinking and fading to nothing.
#   Each spark dies within CRACKLE_REACH of the bloom, between HIPS and CHEST_TOP (`crackle_into` samples the edges of
#   both sprays at both speeds).
CRACKLE_REACH = 1.0
HIPS, CHEST_TOP = 2.0, 3.06  # studs up: the Shade's hips; the lowest of its masks' feet (Dasher's)
HEAVY = 1.4  # the third's pop plays at this scale
STANDOFF = 0.25  # studs before the torso's face where the ember stops and the pop stands
LAND = 2.4  # studs up: the ember flies at the Shade's belly, so its bloom opens under the mask (its foot is 3.81 up)
POP_LIGHT = (8, 5, 7)  # range, brightness, frames to dark
SEED = 31
CLOSE = 5.0  # studs: a Shade that has walked in on him, beside his spacing, for the measures


def line_rows(name, tail, head, width, life, taper, hit=None):
    """One straight line as two Beam rows, as Rook's (rook_combo_fx.line_rows), with or without a beat to count from."""
    rows = rk.line_rows(name, hit, tail, head, width, life, taper)
    if hit is None:
        for row in rows.values():
            row.pop("From")
    return rows


def ring(axis, rake, count, turn, rng):
    """`count` ways round `axis`, each raked `rake` degrees off it, jittered."""
    u = k.unit(rk.cross(axis, [0.0, 1.0, 0.0]) if abs(axis[1]) < 0.95 else rk.cross(axis, [1.0, 0.0, 0.0]))
    v = rk.cross(u, axis)
    out = []
    for i in range(count):
        phi = math.radians(turn + i * 360 / count + rng.uniform(-10, 10))
        r = math.radians(rake + rng.uniform(-5, 5))
        out.append(k.unit(k.add(k.mul(axis, math.cos(r)), k.mul(k.add(k.mul(u, math.cos(phi)), k.mul(v, math.sin(phi))), math.sin(r)))))
    return out


def spits(rng):
    n = measure(list(SPIT_AT.values()))
    target = [0.0, 3.0, -spacing()]
    rows = {}
    for hit, f in SPIT_AT.items():
        s = SPIT[hit]
        lantern = n[f]["Lantern"]
        aim = k.unit(k.sub(target, lantern))
        mouth = k.add(lantern, k.mul(aim, MOUTH))
        for i, way in enumerate(ring(aim, s["rake"], s["lines"], 20, rng)):
            length = (s["long"] if i % 2 == 0 else s["short"]) * rng.uniform(0.9, 1.1)
            rows.update(line_rows(f"{hit}Spit{i + 1}", mouth, k.add(mouth, k.mul(way, length)), s["width"], SPIT_LIFE, 0.3, hit))
        reach, bright, dark = s["light"]
        rows[f"{hit}Flash"] = {"Kind": "Light", "From": hit, "Range": reach, "Color": WHITE,
                               "Why": f"{hit}: the lantern's spit lights him and the street",
                               "Tracks": {"At": [[0, k.v3(mouth)]], "Brightness": [[0, bright, "Quart Out"], [dark, 0]]}}
        turn = math.degrees(math.atan2(-aim[0], -aim[2]))
        rows[f"{hit}Sparks"] = {
            "Kind": "Emitter", "From": hit, "Image": SPARK, "Turn": {"Vector3": [0, round(turn, 1), 0]},
            "Why": f"{hit}: the spit's sparks, thrown at the Shade and dropping away", "Emit": [[0, s["sparks"]]],
            "Emitter": {"EmissionDirection": "Front", "SpreadAngle": [30, 30], "Lifetime": [0.15, 0.3], "Speed": [8, 16],
                        "Drag": 3, "Acceleration": {"Vector3": [0, -30, 0]}, "Size": [[0, 0.25], [1, 0.05]],
                        "Transparency": [[0, 0], [1, 0.4]], "Rotation": [0, 360], "LightEmission": 1, "LightInfluence": 0},
            "Tracks": {"At": [[0, k.v3(mouth)]]}}
        rows[hit] = {"Kind": "Streak", "Body": "Lantern", "From": hit, "Color": {"Color3": [225, 225, 225]}, "Tracks": {},
                     "Why": f"{hit}: the builder's streak from the lantern to the target, until the ember flies (AR26)"}
    return rows


def pop(rng):
    """PipPop's rows in its own frame: at where the ember lands, -Z on into the Shade along its flight, up as up."""
    rows, lines = {}, []
    p = PETALS
    for i, angle in enumerate(p["angles"]):
        a, r = math.radians(angle + rng.uniform(-8, 8)), math.radians(p["rake"] + rng.uniform(-5, 5))
        way = [math.sin(a) * math.sin(r), math.cos(a) * math.sin(r), math.cos(r)]
        length = (p["long"] if i % 2 == 0 else p["short"]) * rng.uniform(0.9, 1.1)
        tail, head = k.mul(way, p["hollow"]), k.mul(way, p["hollow"] + length)
        rows.update(line_rows(f"Petal{i + 1}", tail, head, p["width"], p["life"], 0.35))
        lines.append((tail, head))
    for i, (angle, length, back) in enumerate(FLUNG):
        a = math.radians(angle)
        way = k.unit([math.sin(a), math.cos(a), back])
        tail, head = k.mul(way, 0.3), k.mul(way, 0.3 + length)
        rows.update(line_rows(f"Flung{i + 1}", tail, head, FLUNG_WIDTH, FLUNG_LIFE, 0.4))
        lines.append((tail, head))
    c = CRACKLE
    for side, turn in zip("LR", c["turns"]):
        rows[f"Crackle{side}"] = {
            "Kind": "Emitter", "Image": SPARK, "Turn": {"Vector3": [0, turn, 0]}, "Emit": [[0, c["count"]]],
            "Why": f"the pop's crackle in the air, thrown back toward him and out to his {'left' if turn < 0 else 'right'}: "
                   "slowed hard, barely falling, shrinking and fading to nothing within a stud of the bloom",
            "Emitter": {"EmissionDirection": "Back", "SpreadAngle": [c["spread"], c["spread"]], "Lifetime": list(c["life"]),
                        "Speed": list(c["speed"]), "Drag": c["drag"], "Acceleration": {"Vector3": [0, -c["fall"], 0]},
                        "Size": [[0, 0.22], [1, 0]], "Transparency": [[0, 0], [1, 1]], "Rotation": [0, 360],
                        "LightEmission": 1, "LightInfluence": 0},
            "Tracks": {"At": [[0, {"Vector3": [0, 0, 0.1]}]]}}
    reach, bright, dark = POP_LIGHT
    rows["Light"] = {"Kind": "Light", "Range": reach, "Color": WHITE, "Why": "the pop's light: it rims the Shade from his side",
                     "Tracks": {"At": [[0, {"Vector3": [0, 0, 0.3]}]], "Brightness": [[0, bright, "Quart Out"], [dark, 0]]}}
    return rows, lines


EMBER = {  # the flight's own rows, riding its head (-Z its way): the head's width, the trail's lag in frames, the light
    "PipEmber": {"width": 0.22, "lag": 0.6, "light": (5, 2), "spits": 50, "ribbon": None},
    "PipEmberHeavy": {"width": 0.45, "lag": 0.8, "light": (7, 3), "spits": 80, "ribbon": {"width": 0.9, "lag": 1.3}},
}  # lag in frames: as it lands from 13.5 it runs 3.6 studs a frame, so the tail is 2.2 studs, the heavy's 2.9 and its
#   ribbon 4.6; from 5, about 0.6 of that


def ember(name):
    """An ember's rows in its head's frame, played from the launch on the flight's moving frame. Its trail runs back to
    where the head was `lag` frames before, so it grows as the ember speeds up (about 2.2 studs as it lands from 13.5)."""
    e = EMBER[name]
    beam = {"FaceCamera": True, "TextureMode": "Stretch", "TextureLength": 1, "TextureSpeed": 0,
            "LightEmission": 1, "LightInfluence": 0, "Brightness": 3, "Segments": 1}
    rows = {"Tail": {"Kind": "Beam", "Image": GREY, "Grey": GREY, "Color": WHITE, "Beam": beam, "Taper": 0.15,
                     "Trail": {"Back": 0, "Beyond": 0}, "Why": "the ember: its head, and its tail back along its flight",
                     "Tracks": {"Lag": [[0, e["lag"]]], "Width": [[0, e["width"]]], "Transparency": [[0, 0]]}}}
    if e["ribbon"]:
        r = e["ribbon"]
        rows["Ribbon"] = {"Kind": "Beam", "Image": GREY, "Grey": GREY, "Color": WHITE, "Beam": beam, "Taper": 0.2,
                          "Trail": {"Back": 0, "Beyond": 0}, "Why": "the third's ribbon: a softer, wider trail behind it",
                          "Tracks": {"Lag": [[0, r["lag"]]], "Width": [[0, r["width"]]], "Transparency": [[0, 0.5]]}}
    reach, bright = e["light"]
    rows["Light"] = {"Kind": "Light", "Range": reach, "Color": WHITE, "Why": "the ember's light, carried with it",
                     "Tracks": {"Brightness": [[0, bright]]}}
    rows["Spits"] = {"Kind": "Emitter", "Image": SPARK,
                     "Why": "the ember spits: sparks left behind it in the air as it flies, hanging and fading, never falling",
                     "Emitter": {"EmissionDirection": "Back", "SpreadAngle": [40, 40], "Lifetime": [0.08, 0.15],
                                 "Speed": [2, 4], "Drag": 10, "Acceleration": {"Vector3": [0, 0, 0]},
                                 "Size": [[0, 0.18], [1, 0]], "Transparency": [[0, 0], [1, 1]],
                                 "LightEmission": 1, "LightInfluence": 0},
                     "Tracks": {"Rate": [[0, e["spits"]]]}}
    return {"Schema": "rows/1", "Effect": name,
            "Why": f"Pip's {'third ' if e['ribbon'] else ''}ember (AR26): the flight's own look, played on its head from the "
                   "lantern to where it lands, then the pop. Written by tools/blender/pip_combo_fx.py.",
            "Area": 1, "Grey": True, "Rows": rows}


def landing(ahead):
    """Where the ember lands with the Shade `ahead` studs before him, and its frame: from the lantern's mouth at the
    first beat to the Shade's middle, stopped STANDOFF before the torso's face; -Z along the flight, made level."""
    lantern = measure([HITS["Shot1"]])[HITS["Shot1"]]["Lantern"]
    middle = [0.0, LAND, -ahead]
    d = k.unit(k.sub(middle, lantern))
    front = -ahead + 0.74 + STANDOFF
    hit = k.add(lantern, k.mul(d, (front - lantern[2]) / d[2]))
    level = k.unit([d[0], 0.0, d[2]])  # the pop faces him level, whatever the flight's pitch
    right = k.unit(rk.cross(level, [0.0, 1.0, 0.0]))
    return hit, right, [0.0, 1.0, 0.0], level


def placed(local, frame):
    hit, right, up, d = frame
    return k.add(k.add(k.add(hit, k.mul(right, local[0])), k.mul(up, local[1])), k.mul(d, -local[2]))


def pop_seen(lines, ahead, samples=16, scale=1.0):
    frame = landing(ahead)
    world = [(placed(k.mul(a, scale), frame), placed(k.mul(b, scale), frame)) for a, b in lines]
    boxes = w.shade_boxes(ahead)
    out = {}
    for h in HEADINGS:
        cam = w.camera(ahead, h)
        each = []
        for a, b in world:
            step = k.length(k.sub(b, a)) / samples
            each.append(sum(step for i in range(samples) if not w.covered(k.add(a, k.mul(k.sub(b, a), (i + 0.5) / samples)), cam, boxes)))
        out[h] = each
    return out, world


MARGIN = 0.1  # studs: no line comes nearer a target's part or face than this, and half its own width
SPARK_SIZE = 0.22  # the crackle's sparks at their biggest (their emitter's Size; not grown with the pop)


def pop_into(world, ahead, scale=1.0):
    """Rule 4 for the pop's lines: none comes within MARGIN and half the widest line (at its scale) of a target's
    part or under FLOOR, and no point of one draws over a face from any view: against every target, landed on it as
    the flight lands it (combo_targets: the ordinary Shade under each mask, the elite, the Lamplighter)."""
    points = [p for a, b in world for p in ct.along(a, b)]
    bad = ct.rule4(points, ahead, f"the pop at {scale}", land=LAND, margin=MARGIN + PETALS["width"] / 2 * scale)
    for i, (a, b) in enumerate(world):
        if min(a[1], b[1]) < FLOOR:
            bad.append(f"pop line {i + 1} comes down to {min(a[1], b[1]):.2f} up (the Shade {ahead} ahead)")
    return bad


def crackle_paths(ahead, scale, steps=12):
    """Where the crackle's sparks can go: the middle and eight edges of each spray, at its slowest and fastest, over the
    longest life, slowed by its drag (on the throw only: the fall is taken whole, the worse case) and its fall."""
    c = CRACKLE
    frame = landing(ahead)
    start = k.mul([0.0, 0.0, 0.1], scale)
    s = math.radians(c["spread"])
    paths = []
    for turn in c["turns"]:
        t_ = math.radians(turn)
        axis, side = [math.sin(t_), 0.0, math.cos(t_)], [math.cos(t_), 0.0, -math.sin(t_)]
        ways = [axis] + [k.unit(k.add(k.mul(axis, math.cos(s)), k.mul(k.add(k.mul(side, math.cos(q)), k.mul([0.0, 1.0, 0.0], math.sin(q))), math.sin(s))))
                         for q in (math.radians(45 * i) for i in range(8))]
        for way, speed in itertools.product(ways, c["speed"]):
            path = []
            for i in range(steps + 1):
                t = c["life"][1] * i / steps
                thrown = speed * (1 - 2 ** (-c["drag"] * t)) / (c["drag"] * math.log(2))
                local = k.add(k.add(start, k.mul(way, thrown)), [0.0, -0.5 * c["fall"] * t * t, 0.0])
                path.append(placed(local, frame))
            paths.append(path)
    return paths, placed(start, frame)


def crackle_into(ahead, scale, margin=MARGIN):
    """Rule 4 for the crackle (the content check, 2026-11-17): a crackle in the air, never sparks shed from the struck
    body falling to its feet. Every spark stays within CRACKLE_REACH of the bloom, between HIPS and CHEST_TOP (on the
    ordinary Shade), out of every target's parts and off its faces from every view, as pop_into."""
    paths, bloom = crackle_paths(ahead, scale)
    bad = []
    points = [p for path in paths for p in path]
    far = max(k.length(k.sub(p, bloom)) for p in points)
    low, high = min(p[1] for p in points), max(p[1] for p in points)
    if far > CRACKLE_REACH + 1e-9:
        bad.append(f"the crackle reaches {far:.2f} from the bloom (the Shade {ahead} ahead)")
    if low < HIPS or high > CHEST_TOP:
        bad.append(f"the crackle runs {low:.2f} to {high:.2f} up (the Shade {ahead} ahead)")
    bad += ct.rule4(points, ahead, f"the crackle at {scale}", land=LAND, margin=margin + SPARK_SIZE / 2)
    return bad, (far, low, high)


def effects():
    rng = random.Random(SEED)
    shots = {"Schema": "rows/1", "Effect": "PipShots",
             "Why": "Pip's shots (PipCombo), the grey block (AR26; research's feel line, 08:06): on each beat the lantern "
                    "spits, lines, sparks and a light at its place on that frame, and the builder's streak runs to the "
                    "target until the ember flies. Written by tools/blender/pip_combo_fx.py.",
             "Area": 1, "Grey": True, "Action": ACTION, "Rows": spits(rng)}
    rows, lines = pop(rng)
    popped = {"Schema": "rows/1", "Effect": "PipPop",
              "Why": "Pip's pop (AR26): where his ember lands, facing its flight, played by its streak: petals off the "
                     "Shade's front, sparks flung past its outline, a crackle and a light. The third plays it bigger. "
                     "Written by tools/blender/pip_combo_fx.py.",
              "Area": 1, "Grey": True, "Rows": rows}
    return shots, popped, lines


def write_rows(out):
    read_action()
    shots, popped, lines = effects()
    embers = [ember(name) for name in EMBER]
    problems = k.check(shots, USED) + k.check(popped, USED) + sum((k.check(e, USED) for e in embers), [])
    problems += [f"flung spark {i + 1} aims {abs(a - 180)} degrees off straight down" for i, (a, _, _) in enumerate(FLUNG)
                 if abs(a - 180) < DOWN_CLEAR]
    for ahead in (spacing(), CLOSE):
        for scale in (1.0, HEAVY):
            problems += pop_into(pop_seen(lines, ahead, scale=scale)[1], ahead, scale)
            problems += crackle_into(ahead, scale)[0]
    if problems:
        raise SystemExit("the rows don't pass their own check:\n  " + "\n  ".join(problems))
    out.mkdir(parents=True, exist_ok=True)
    for e in (shots, popped, *embers):
        (out / f"{e['Effect']}.rows.json").write_text(json.dumps(e, indent=1) + "\n", encoding="utf-8")
        print(f"Written to {out}: {e['Effect']} ({len(e['Rows'])} rows)")
    for ahead in (spacing(), CLOSE):
        for scale in (1.0, HEAVY):
            far, low, high = crackle_into(ahead, scale)[1]
            print(f"  the crackle, the Shade {ahead} ahead, at {scale}: within {far:.2f} of the bloom, {low:.2f} to {high:.2f} up")
    print(f"  every pop line is above {FLOOR} up, and the pop and the crackle clear every target and its faces from "
          f"{len(ct.VIEWS)} views, landed as the flight lands them: {', '.join(ct.targets())}")
    for ahead in (spacing(), CLOSE):
        seen, _ = pop_seen(lines, ahead)
        print(f"  the pop, the Shade {ahead} ahead: studs seen of petals 1-{len(PETALS['angles'])} | flung, by heading")
        for h, each in seen.items():
            petals, flung = each[:len(PETALS["angles"])], each[len(PETALS["angles"]):]
            print(f"    {h:3d}: " + " ".join(f"{s:.1f}" for s in petals) + " | " + " ".join(f"{s:.1f}" for s in flung)
                  + f"  = {sum(petals):.1f} + {sum(flung):.1f}")


def main():
    if sys.argv[1:2] == ["rows"] and len(sys.argv) > 2:
        write_rows(Path(sys.argv[2]))
        return
    if sys.argv[1:2] == ["measure"]:
        act = read_action()
        n = measure()
        print(f"beats {act['beats']}, range {act['range']}, spacing {act['range'] - APPROACH}")
        last = None
        for f, p in n.items():
            speed = k.length(k.sub(p["Lantern"], last)) * 60 if last else 0.0
            last = p["Lantern"]
            mark = next((h for h, v in HITS.items() if v == f), "")
            print(f"{f:3d} {mark:5s} " + " ".join(f"{name}=({v[0]:+.2f},{v[1]:+.2f},{v[2]:+.2f})" for name, v in p.items())
                  + f"  lantern {speed:5.1f} st/s")
        return
    if sys.argv[1:2] == ["screen"]:
        screen()
        return
    print(__doc__)
    sys.exit(2)


if __name__ == "__main__":
    main()
