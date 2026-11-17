"""Rook's basic attack, its look as rows (AR26, Rook second; /ga-action steps 1 and 3; AR8, "The method").

py tools/blender/rook_combo_fx.py measure
py tools/blender/rook_combo_fx.py screen
py tools/blender/rook_combo_fx.py rows <out_dir>

Plain Python, no Blender. Its numbers come from the delivered clip (build/handoff/Rook/clips/Rook_Combo.json, the
Transforms the game plays) on R6's shoulders and the recipe's piston joint, and from the action's own row (read only:
src/shared/Definitions/Actions.luau, RookCombo's Beats).
- measure: the taped fist, the ram's face and its middle in his root's frame through the clip, with the fists' speed.
- screen: where each hit's fist lands on a phone's screen from the game's camera, and whether the Shade covers it.
- rows: RookCombo.rows.json, schema rows/1 (docs/engineering-plan.md, "The rows contract"), in grey.
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

ROOT = Path(__file__).resolve().parents[2]
RECIPE = ROOT / "build" / "handoff" / "Rook" / "Rook.recipe.json"
CLIP = ROOT / "build" / "handoff" / "Rook" / "clips" / "Rook_Combo.json"
ACTIONS = ROOT / "src" / "shared" / "Definitions" / "Actions.luau"  # read only
ACTION = "RookCombo"
HITS = {"Hit1": 12, "Hit2": 48, "Hit3": 86}  # the clip's markers, checked against it and against the action's Beats
ROOT_HEIGHT = 3.0  # R6: the HumanoidRootPart's centre over the floor
PISTON = "Rook_Piston"
# R6's shoulders, C0 and C1 as rotation rows and a place (Roblox's own rig)
RIGHT_SHOULDER = (([[0, 0, 1], [0, 1, 0], [-1, 0, 0]], [1, 0.5, 0]), ([[0, 0, 1], [0, 1, 0], [-1, 0, 0]], [-0.5, 0.5, 0]))
LEFT_SHOULDER = (([[0, 0, -1], [0, 1, 0], [1, 0, 0]], [-1, 0.5, 0]), ([[0, 0, -1], [0, 1, 0], [1, 0, 0]], [0.5, 0.5, 0]))
ARM_REST = {"Right Arm": [1.5, ROOT_HEIGHT, 0.0], "Left Arm": [-1.5, ROOT_HEIGHT, 0.0]}
FIST = [0.0, -1.05, 0.0]  # the taped fist's knuckles, in the left arm's frame: the hand's foot


def read_action():
    text = ACTIONS.read_text(encoding="utf-8")
    start = text.index(f'Id = "{ACTION}"')
    block = text[start:text.index("Id = ", start + 10)]
    beats = {n: round(float(v) * 60) for n, v in re.findall(r"(\w+) = ([\d.]+)", re.search(r"Beats = \{([^}]*)\}", block).group(1))}
    if beats != HITS:
        raise SystemExit(f"the action's beats moved: {beats}")
    push = {h: float(re.search(rf"{h} = \{{[^}}]*Push = ([\d.]+)", block).group(1)) for h in HITS}
    return {"beats": beats, "push": push, "range": float(re.search(r"\bRange = ([\d.]+)", block).group(1))}


def measure(frames=None):
    """The fists in his root's frame, frame by frame (x right, y from the floor, z back): Fist the taped left's knuckles,
    Face the ram's striking face, Ram its middle (so Ram to Face is the way the ram drives)."""
    recipe = json.loads(RECIPE.read_text(encoding="utf-8"))
    clip = json.loads(CLIP.read_text(encoding="utf-8"))
    marks = {m["Name"]: round(m["T"] * clip["Fps"]) for m in clip["Markers"]}
    if marks != HITS:
        raise SystemExit(f"the clip's markers moved: {marks}")
    points = {p["name"]: p["at"] for p in recipe["points"]}
    piston = next(p for p in recipe["pieces"] if p["name"] == PISTON)
    if piston["on"] != "Right Arm":
        raise SystemExit("the piston isn't on the right arm")
    out = {}
    for f in frames if frames is not None else range(len(clip["Frames"])):
        poses = clip["Frames"][f]["Poses"]
        torso = k.compose(k.compose(k.R6_ROOT, k.cframe(poses["Torso"])), k.inverse(k.R6_ROOT))
        arms = {}
        for arm, (c0, c1) in (("Right Arm", RIGHT_SHOULDER), ("Left Arm", LEFT_SHOULDER)):
            arms[arm] = k.compose(torso, k.compose(k.compose(c0, k.cframe(poses[arm])), k.inverse(c1)))
        joint = k.compose(k.compose(arms["Right Arm"], k.moved(k.sub(piston["pivot"], ARM_REST["Right Arm"]))),
                          k.cframe(poses[PISTON]))

        def on_ram(name):
            return k.add(k.compose(joint, k.moved(k.sub(points[name], piston["pivot"])))[1], [0, ROOT_HEIGHT, 0])

        out[f] = {"Fist": k.add(k.compose(arms["Left Arm"], k.moved(FIST))[1], [0, ROOT_HEIGHT, 0]),
                  "Face": on_ram("Knuckles"), "Ram": on_ram("RamCentre"),
                  "Reach": k.unit(k.rot(arms["Left Arm"][0], [0.0, -1.0, 0.0]))}  # the taped arm's way, shoulder to fist
    return out


SPACING = w.SPACING  # studs, his root to the target's: the action's Range less Config.Combat's Approach
HEADINGS = w.HEADINGS  # the replay's camera (215), its mirror, ±70 round the fight (Faber's takes), the clip's review camera


def screen():
    """Where each hit's fist and the ram land on the phone's screen from the game's camera, and what the Shade covers."""
    n = measure([f for h in HITS.values() for f in (h - 2, h, h + 2)])
    boxes = w.shade_boxes(SPACING)
    for h in HEADINGS:
        cam = w.camera(SPACING, h)
        print(f"heading {h}:")
        for hit, f0 in HITS.items():
            cells = []
            for f in (f0 - 2, f0, f0 + 2):
                for name, p in n[f].items():
                    s = w.on_screen(p, cam)
                    cells.append(f"{f}{name[0]} ({s[0]:+.2f},{s[1]:+.2f}){'#' if w.covered(p, cam, boxes) else ''}")
            print(f"  {hit}: " + " ".join(cells))
    print("(shares of the screen's height from its middle; # the Shade covers it)")


# --- the rows: the hero is the burst, then the cone ---------------------------------------------------------------
# Research's feel line (AR26, signed 08:06, its camera corrected 08:16): the jab and the hook snap a tight burst off the
# knuckles; the ram drives a short cone of dust and light through the Shade, and it opens the space it pushes. A street
# fight, fists first, the third hit heavy. Every melee hero shape reads with the Shade between the camera and its touch.
# Measured (screen, escapes): at the main framing (215) the jab's fist lands in the open, 40 degrees to his left as the
# clip aimed it; the hook's ram face lands 0.27 studs before the Shade's left arm, behind it; the ram goes into the
# street 1.5 ahead, behind the Shade's legs, and a line along the street toward the Shade clears it once past.
# Hits 1 and 2: straight spikes round the knuckles on a hollow ring, long and short in turn: the jab's flared out
# off the outside of the shoulder it lands beside, the hook's a narrow glance up off the arm's front. They snap out in a frame and a half, hold through
# the hitstop, then fly off their tips and thin out. Hit 3: a cone of straight lines from the ram's foot along the
# street, through the Shade's feet the way it's pushed: low through its legs, rising beside them as it opens, with dust
# thrown the same way and slowing, and a light that runs through with it. Jab, hook, ram: 1.25, 2.1, then 3.4 to 4.8
# studs, each heavier. Rule 4, by `into`: no spike comes within CLEAR of the Shade, and no cone line is inside it above
# LEG_LINE, and no spike's end draws over the head from a heading, with the Shade at its spacing or pushed back (the
# content check of 2026-11-17: never a stab, never a stake, never a point on a head).
# DESIGN seeds, frames after the hit's beat on the action's clock (so a hitstop holds them), tuned live.
GREY = "fx_beam"
DUST = "fx_glow"  # the block's dust: the kit's soft round light, lit by the scene (Kirra's Puff); the puff sheet at the finish
WHITE = {"Color3": [255, 255, 255]}
USED = (GREY, DUST)
SEED = 27  # the burst's dice: fixed, so the file is the same each run
BURST = {  # per hit: spikes, long and short studs, the ring's hollow, their rake off the blow (degrees), the ring's turn
    "Hit1": {"spikes": 6, "long": 1.25, "short": 0.7, "hollow": 0.3, "rake": 50, "turn": 36, "width": 0.17},
    "Hit2": {"spikes": 6, "long": 2.1, "short": 1.16, "hollow": 0.35, "rake": 20, "turn": 15, "width": 0.2},
}
# The jab lands beside the Shade's right shoulder, just under its head, so its burst flares off the outside: round its
# reach turned JAB_FLARE, out to his left and down, away from the head. Of the axes, rakes and turns tried, the few that
# keep every spike CLEAR of the Shade and off the head's outline from every heading (`into`) all flare out this way;
# this one shows the most at 215 (6.0 studs, all six lines). The hook
# lands on the front of the Shade's left arm, 0.27 studs before it, so its burst can't open forward: it glances, a
# narrow spray up off the arm's front, out to his right and back toward him (HOOK_GLANCE). Of every axis, rake and
# turn that keeps each spike CLEAR of the Shade, this shows the most at 215 (1.4 studs on two lines); a wider burst
# shows 0.9 on one.
JAB_FLARE = (40, -20)  # degrees round off the jab's reach toward his left; degrees up (here down)
HOOK_GLANCE = (50, 60)  # degrees up; degrees round from straight back (+z, toward him) toward his right
CLEAR = 0.18  # studs: no spike comes nearer the Shade's parts than this (the jab's spike 1 passes the arm at 0.19)
SNAP, HOLD, OFF = 1.5, 4, 8  # frames: out to their tips; held whole; flown off their tips and gone (0.13 s)
CONE = [(-20, 2, 4.6), (-8, 3, 4.2), (2, 3, 4.8), (12, 12, 3.8), (22, 17, 3.4)]  # each line: degrees off the aim toward
#   his right, degrees up off the street, studs long. The three through the Shade's legs rush low along the street (a
#   line inside a Shade part stays under LEG_LINE: 3 degrees up at most from the ram's foot); the two on his right pass
#   beside the Shade's left leg and rise, shorter, as the cone opens.
LEG_LINE = 0.4  # studs up: a cone line inside a Shade part stays below this, a rush along the ground, never a stake
CONE_HOLLOW, CONE_WIDTH = 0.35, 0.24
CONE_PAST = 2.0  # the cone's aim: through the Shade's feet to this far past its middle, the way the ram pushes it, so its
#                  lines come out of the Shade's back toward the camera (aimed at its middle, 3.4 studs showed at 215)
CONE_DRAW, CONE_HOLD, CONE_GONE = 3, 5, 11  # out in three frames, fast at first; gone by 11 (0.18 s)
UP = [0.0, 1.0, 0.0]


def cross(a, b):
    return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]


def line_rows(name, hit, tail, head, width, life, taper):
    """One straight line, two rows: the Beam at its tail, and its tip (a blank Beam, only for the place). The tip runs
    out from the tail (Quart Out), both hold, then the tail runs up to near the tip as it thins: it flies off its tip."""
    draw, hold, gone = life
    near = k.add(tail, k.mul(k.sub(head, tail), 0.82))
    beam = {"FaceCamera": True, "TextureMode": "Stretch", "TextureLength": 1, "TextureSpeed": 0,
            "LightEmission": 1, "LightInfluence": 0, "Brightness": 3, "Segments": 1}
    return {
        name: {"Kind": "Beam", "Image": GREY, "Grey": GREY, "Color": WHITE, "From": hit, "Beam": beam,
               "High": f"{name}Tip.Low", "Taper": taper, "Why": f"{name}: a line off the touch",
               "Tracks": {"At": [[0, k.v3(tail), "Linear"], [hold, k.v3(tail), "Quad In"], [gone, k.v3(near)]],
                          "Foot": [[0, 0]],
                          "Width": [[0, round(width * 0.6, 3), "Quart Out"], [1, width, "Linear"], [hold, width, "Quad In"],
                                    [gone, round(width * 0.3, 3)]],
                          "Transparency": [[0, 0, "Linear"], [hold + 1, 0, "Quad In"], [gone, 1]]}},
        f"{name}Tip": {"Kind": "Beam", "Image": GREY, "Grey": GREY, "Color": WHITE, "From": hit, "Beam": beam,
                       "Why": f"{name}'s tip: a place for its line, never shown",
                       "Tracks": {"At": [[0, k.v3(tail), "Quart Out"], [draw, k.v3(head)]], "Foot": [[0, 0]],
                                  "Width": [[0, 0]]}},
    }


def burst(hit, touch, axis, rng):
    """Spikes round the knuckles on a hollow ring, raked `rake` degrees off the blow, long and short in turn."""
    b = BURST[hit]
    u = k.unit(cross(axis, UP))
    v = cross(u, axis)
    rows, lines = {}, []
    for i in range(b["spikes"]):
        phi = math.radians(b["turn"] + i * 360 / b["spikes"] + rng.uniform(-8, 8))
        rake = math.radians(b["rake"] + rng.uniform(-8, 8))
        way = k.unit(k.add(k.mul(axis, math.cos(rake)),
                           k.mul(k.add(k.mul(u, math.cos(phi)), k.mul(v, math.sin(phi))), math.sin(rake))))
        length = (b["long"] if i % 2 == 0 else b["short"]) * rng.uniform(0.92, 1.08)
        tail, head = k.add(touch, k.mul(way, b["hollow"])), k.add(touch, k.mul(way, b["hollow"] + length))
        rows.update(line_rows(f"{hit}Spike{i + 1}", hit, tail, head, b["width"], (SNAP, HOLD, OFF), 0.3))
        lines.append((tail, head))
    rows[f"{hit}Light"] = {"Kind": "Light", "From": hit, "Range": 7, "Color": WHITE,
                           "Why": "the knuckles' light: it rims the Shade where the touch is behind it",
                           "Tracks": {"At": [[0, k.v3(touch)]], "Brightness": [[0, 4, "Quart Out"], [6, 0]]}}
    return rows, lines


def cone(foot, aim, ahead):
    """Hit 3: straight lines from the ram's foot along the street, rising as the cone opens, through and past the
    Shade; the dust thrown with them, slowing; a light that runs through the Shade with them."""
    rows, lines = {}, []
    yaw0 = math.atan2(aim[0], -aim[2])  # from ahead toward his right
    for i, (yaw, rise, length) in enumerate(CONE):
        y, r = yaw0 + math.radians(yaw), math.radians(rise)
        way = [math.sin(y) * math.cos(r), math.sin(r), -math.cos(y) * math.cos(r)]
        tail, head = k.add(foot, k.mul(way, CONE_HOLLOW)), k.add(foot, k.mul(way, CONE_HOLLOW + length))
        rows.update(line_rows(f"Hit3Cone{i + 1}", "Hit3", tail, head, CONE_WIDTH * (0.85 if rise > 10 else 1.0),
                              (CONE_DRAW, CONE_HOLD, CONE_GONE), 0.35))
        lines.append((tail, head))
    turn = math.degrees(math.atan2(-aim[0], -aim[2]))  # Front (-Z) turned about up onto the aim
    rows["Hit3Dust"] = {
        "Kind": "Emitter", "From": "Hit3", "Image": DUST, "Turn": {"Vector3": [0, round(turn, 1), 0]},
        "Why": "the dust the ram throws along the cone, fast then slowing, out past the Shade's feet",
        "Emit": [[0, 12]],
        "Emitter": {"EmissionDirection": "Front", "SpreadAngle": [20, 20], "Lifetime": [0.35, 0.6], "Speed": [9, 15],
                    "Drag": 5, "Acceleration": {"Vector3": [0, 2, 0]}, "Size": [[0, 0.9], [1, 2.4]],
                    "Transparency": [[0, 0.4], [1, 1]], "Rotation": [0, 360], "RotSpeed": [-60, 60],
                    "LightEmission": 0.2, "LightInfluence": 0.7},
        "Tracks": {"At": [[0, k.v3(k.add(foot, [0, 0.25, 0]))]]}}
    through = [0.0, 1.0, -(ahead + 0.6)]
    rows["Hit3Light"] = {"Kind": "Light", "From": "Hit3", "Range": 10, "Color": WHITE,
                         "Why": "the ram's light, run through the Shade with the cone: it lights the Shade from his side",
                         "Tracks": {"At": [[0, k.v3(k.add(foot, [0, 0.6, 0])), "Quad Out"], [4, k.v3(through)]],
                                    "Brightness": [[0, 6, "Quart Out"], [10, 0]]}}
    return rows, lines


def flare(reach):
    """The jab's burst axis: its reach turned JAB_FLARE round toward his left, then tipped up (here down)."""
    y, p = (math.radians(a) for a in JAB_FLARE)
    x, z = reach[0] * math.cos(y) + reach[2] * math.sin(y), -reach[0] * math.sin(y) + reach[2] * math.cos(y)
    return k.unit([x, math.hypot(x, z) * math.tan(p) + reach[1], z])


def effect(ahead=SPACING):
    n = measure([12, 47, 48, 87])
    rng = random.Random(SEED)
    rows, lines = {}, {}
    up, round_ = (math.radians(a) for a in HOOK_GLANCE)
    glance = [math.cos(up) * math.sin(round_), math.sin(up), math.cos(up) * math.cos(round_)]
    for hit, touch, axis in (("Hit1", n[12]["Fist"], flare(n[12]["Reach"])), ("Hit2", n[48]["Face"], glance)):
        r, ls = burst(hit, touch, axis, rng)
        rows.update(r)
        lines[hit] = ls
    foot = [n[87]["Face"][0], 0.15, n[87]["Face"][2]]  # where the piston drives the ram into the street
    aim = k.unit([-foot[0], 0.0, -(ahead + CONE_PAST) - foot[2]])  # through the Shade's feet, the way it's pushed
    r, ls = cone(foot, aim, ahead)
    rows.update(r)
    lines["Hit3"] = ls
    return {"Schema": "rows/1", "Effect": ACTION,
            "Why": "Rook's basic attack, the grey block (AR26; research's feel line, 08:06, its camera 08:16): on the jab "
                   "and the hook a tight burst of spikes snaps off the knuckles; on the ram a cone of lines and dust runs "
                   "from its foot along the street, through the Shade and past it. On the action's clock, so a hitstop "
                   f"holds it. The touches are placed for the Shade {ahead} ahead, his fighting spacing. Written by "
                   "tools/blender/rook_combo_fx.py.",
            "Area": 1, "Grey": True, "Action": ACTION, "Rows": rows}, lines


def seen(lines, ahead=SPACING, samples=16):
    """Studs of each line, whole, that the Shade doesn't cover, from each of HEADINGS."""
    boxes = w.shade_boxes(ahead)
    out = {}
    for hit, segs in lines.items():
        for h in HEADINGS:
            cam = w.camera(ahead, h)
            each = []
            for a, b in segs:
                step = k.length(k.sub(b, a)) / samples
                each.append(sum(step for i in range(samples)
                                if not w.covered(k.add(a, k.mul(k.sub(b, a), (i + 0.5) / samples)), cam, boxes)))
            out.setdefault(hit, []).append((h, each, [k.length(k.sub(b, a)) for a, b in segs]))
    return out


AHEADS = (SPACING, SPACING + 0.4, SPACING + 0.8)  # the Shade at his spacing, and pushed back by the jab and the hook


def outline(points):
    """The convex outline of points on the screen, anticlockwise."""
    pts = sorted(set(map(tuple, points)))

    def half(seq):
        out = []
        for p in seq:
            while len(out) >= 2 and ((out[-1][0] - out[-2][0]) * (p[1] - out[-2][1])
                                     - (out[-1][1] - out[-2][1]) * (p[0] - out[-2][0])) <= 0:
                out.pop()
            out.append(p)
        return out

    return half(pts)[:-1] + half(pts[::-1])[:-1]


def over_head(seg, ahead):
    """The heading from which a spike's end (its last 18%, what's left as it flies off) draws over the head's outline,
    nearer the camera than the head; None when it never does (the content check, 2026-11-17: never a point on a head)."""
    c, h = w.shade_boxes(ahead)[-1]
    corners = [[c[j] + s[j] * h[j] for j in range(3)] for s in itertools.product((-1, 1), repeat=3)]
    a, b = seg
    for heading in HEADINGS:
        cam = w.camera(ahead, heading)
        poly = outline([w.on_screen(q, cam) for q in corners])
        far = max(k.dot(k.sub(q, cam[0]), cam[1]) for q in corners)
        for t in (0.82, 0.88, 0.94, 1.0):
            p = k.add(a, k.mul(k.sub(b, a), t))
            s = w.on_screen(p, cam)
            if k.dot(k.sub(p, cam[0]), cam[1]) < far and all(
                    (q[0] - o[0]) * (s[1] - o[1]) - (q[1] - o[1]) * (s[0] - o[0]) >= 0 for o, q in zip(poly, poly[1:] + poly[:1])):
                return heading
    return None


def into(lines, samples=400):
    """Every line that enters the Shade at any of AHEADS (the rows are fixed; the Shade moves): a spike that comes
    within CLEAR of a part or whose end draws over the head from a heading, or a cone line inside a part above
    LEG_LINE. Rule 4: nothing reads as piercing a body."""
    bad = []
    for ahead in AHEADS:
        boxes = w.shade_boxes(ahead)
        for hit in ("Hit1", "Hit2"):
            for i, seg in enumerate(lines.get(hit, [])):
                heading = over_head(seg, ahead)
                if heading is not None:
                    bad.append(f"{hit} line {i + 1} ends over the head from {heading} (the Shade {ahead} ahead)")
        for hit, segs in lines.items():
            margin, floor = (0.0, LEG_LINE) if hit == "Hit3" else (CLEAR, -1.0)
            for i, (a, b) in enumerate(segs):
                for step in range(samples + 1):
                    p = k.add(a, k.mul(k.sub(b, a), step / samples))
                    if p[1] > floor and any(all(abs(p[j] - c[j]) < h[j] + margin for j in range(3)) for c, h in boxes):
                        bad.append(f"{hit} line {i + 1} enters the Shade at {k.v3(p)['Vector3']} (the Shade {ahead} ahead)")
                        break
    return bad


def write_rows(out):
    read_action()
    e, lines = effect()
    problems = k.check(e, USED) + into(lines)
    if problems:
        raise SystemExit("the rows don't pass their own check:\n  " + "\n  ".join(problems))
    out.mkdir(parents=True, exist_ok=True)
    (out / f"{ACTION}.rows.json").write_text(json.dumps(e, indent=1) + "\n", encoding="utf-8")
    print(f"Written to {out}: {ACTION} ({len(e['Rows'])} rows)")
    print(f"  no line enters the Shade or ends over its head, at {', '.join(str(a) for a in AHEADS)} ahead")
    for ahead in (SPACING, SPACING + 0.8):
        print(f"  the Shade {ahead} ahead: studs seen of each line, whole, by heading (of their lengths)")
        for hit, cells in seen(lines, ahead).items():
            for h, each, total in cells:
                print(f"    {hit} {h:3d}: " + " ".join(f"{s:.1f}" for s in each)
                      + f"  = {sum(each):.1f} of {sum(total):.1f}, {sum(1 for s in each if s >= 0.4)} lines show")


def main():
    if sys.argv[1:2] == ["rows"] and len(sys.argv) > 2:
        write_rows(Path(sys.argv[2]))
        return
    if sys.argv[1:2] == ["measure"]:
        act = read_action()
        n = measure()
        print(f"beats {act['beats']}, push {act['push']}, range {act['range']}")
        last = None
        for f, p in n.items():
            speeds = [k.length(k.sub(p[q], last[q])) * 60 if last else 0.0 for q in ("Fist", "Face")]
            last = p
            mark = next((h for h, v in HITS.items() if v == f), "")
            print(f"{f:3d} {mark:4s} " + " ".join(f"{name}=({v[0]:+.2f},{v[1]:+.2f},{v[2]:+.2f})" for name, v in p.items())
                  + f"  fist {speeds[0]:5.1f} face {speeds[1]:5.1f} st/s")
        print("(his root's frame, y from the floor: x right, z back; the Shade stands at -z, "
              f"its chest's face {SPACING - 0.74:.2f} ahead)")
        return
    if sys.argv[1:2] == ["screen"]:
        screen()
        return
    print(__doc__)
    sys.exit(2)


if __name__ == "__main__":
    main()
