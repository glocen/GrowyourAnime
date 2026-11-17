"""Watt's basic attack, its look as rows (AR26, Watt first; /ga-action steps 1 and 3; AR8, "The method").

py tools/blender/watt_combo_fx.py measure
py tools/blender/watt_combo_fx.py rows <out_dir>

Plain Python, no Blender. Its numbers come from the delivered clip (build/handoff/Watt/clips/Watt_Combo.json, the
Transforms the game plays) on the recipe's one joint, the spear on the Torso, and from the action's own row (read only:
src/shared/Definitions/Actions.luau, WattCombo's Beats and Reach).
- measure: the spear's blade point, head and butt in his root's frame through the clip, with the point's speed.
- rows: WattCombo.rows.json, schema rows/1 (docs/engineering-plan.md, "The rows contract"), in grey.
"""
import json
import math
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kirra_scarf_step_fx as k  # noqa: E402  (the CFrame sums, the Track reader, the rows file check)
import combo_targets as ct  # noqa: E402  (every target the crack lands on, and rule 4's guards against them)

ROOT = Path(__file__).resolve().parents[2]
RECIPE = ROOT / "build" / "handoff" / "Watt" / "Watt.recipe.json"
CLIP = ROOT / "build" / "handoff" / "Watt" / "clips" / "Watt_Combo.json"
ACTIONS = ROOT / "src" / "shared" / "Definitions" / "Actions.luau"  # read only
ACTION = "WattCombo"
HITS = {"Hit1": 21, "Hit2": 36, "Hit3": 60}  # the clip's markers, checked against it and against the action's Beats
ROOT_HEIGHT = 3.0  # R6: the HumanoidRootPart's centre over the floor
SPEAR = "Watt_Spear"
POINTS = ("Blade", "SpearHead", "Butt")


def read_action():
    text = ACTIONS.read_text(encoding="utf-8")
    start = text.index(f'Id = "{ACTION}"')
    block = text[start:text.index("Id = ", start + 10)]
    beats = {n: round(float(v) * 60) for n, v in re.findall(r"(\w+) = ([\d.]+)", re.search(r"Beats = \{([^}]*)\}", block).group(1))}
    if beats != HITS:
        raise SystemExit(f"the action's beats moved: {beats}")
    reach = {h: float(re.search(rf"{h} = \{{[^}}]*Reach = ([\d.]+)", block).group(1)) for h in HITS}
    return {"beats": beats, "reach": reach, "range": float(re.search(r"\bRange = ([\d.]+)", block).group(1))}


def measure(frames=None):
    """The spear's points in his root's frame, frame by frame (x right, y from the floor, z back)."""
    recipe = json.loads(RECIPE.read_text(encoding="utf-8"))
    clip = json.loads(CLIP.read_text(encoding="utf-8"))
    marks = {m["Name"]: round(m["T"] * clip["Fps"]) for m in clip["Markers"]}
    if marks != HITS:
        raise SystemExit(f"the clip's markers moved: {marks}")
    points = {p["name"]: p["at"] for p in recipe["points"]}
    spear = next(p for p in recipe["pieces"] if p["name"] == SPEAR)
    if spear["on"] != "Torso":
        raise SystemExit("the spear isn't on the Torso")
    torso_rest = [0.0, ROOT_HEIGHT, 0.0]
    out = {}
    for f in frames if frames is not None else range(len(clip["Frames"])):
        poses = clip["Frames"][f]["Poses"]
        torso = k.compose(k.compose(k.R6_ROOT, k.cframe(poses["Torso"])), k.inverse(k.R6_ROOT))
        joint = k.compose(k.compose(torso, k.moved(k.sub(spear["pivot"], torso_rest))), k.cframe(poses[SPEAR]))
        out[f] = {n: k.add(k.compose(joint, k.moved(k.sub(points[n], spear["pivot"])))[1], [0, ROOT_HEIGHT, 0])
                  for n in POINTS}
    return out


SPACING = 3.5  # studs, his root to the target's: the action's Range less Config.Combat's Approach, where a lead fights from
FOV = 70.0  # Roblox's default vertical field
ASPECT = 16 / 9  # a phone held landscape


def shade_boxes(ahead):
    """The Shade's parts at rest as boxes (centre, half size) in his foot's frame, `ahead` studs before him, facing him."""
    recipe = json.loads(k.SHADE_RECIPE.read_text(encoding="utf-8"))
    parts = [p for p in recipe["pieces"] if "centre" in p] + [recipe["masks"][k.MASK]]
    return [([-p["centre"][0], p["centre"][1], -p["centre"][2] - ahead], [s / 2 for s in p["size"]]) for p in parts]


def camera(ahead, heading=k.REPLAY_HEADING):
    """The game's camera in his foot's frame: round the Shade's chest at `heading` (0 behind him, 90 on his right)."""
    h = math.radians(heading)
    chest = [0.0, k.CHEST, -ahead]
    eye = k.add(chest, [math.sin(h) * k.CAMERA_OUT, k.CAMERA_UP, math.cos(h) * k.CAMERA_OUT])
    fwd = k.unit(k.sub(chest, eye))
    right = k.unit([-fwd[2], 0.0, fwd[0]])
    up = [right[1] * fwd[2] - right[2] * fwd[1], right[2] * fwd[0] - right[0] * fwd[2], right[0] * fwd[1] - right[1] * fwd[0]]
    return eye, fwd, right, up


def on_screen(p, cam):
    """A point's place on the screen: x and y as shares of the screen's height from its middle (right and up +)."""
    eye, fwd, right, up = cam
    d = k.sub(p, eye)
    z = k.dot(d, fwd)
    f = 1 / math.tan(math.radians(FOV) / 2)
    return [k.dot(d, right) / z * f / 2, k.dot(d, up) / z * f / 2]


def covered(p, cam, boxes):
    eye = cam[0]
    to = k.sub(p, eye)
    far = k.length(to)
    way = k.mul(to, 1 / far)
    return any(e and e[0] < far for e in (k.entering(eye, way, b) for b in boxes))


def screen():
    """Where the hits' places land on the phone's screen from the game's camera, and whether the Shade covers them."""
    n = measure(list(HITS.values()))
    for ahead in (SPACING, SPACING + 1.0):
        cam, boxes = camera(ahead), shade_boxes(ahead)
        outline = [on_screen(c, cam) for b in boxes for c in
                   ([b[0][0] + sx * b[1][0], b[0][1] + sy * b[1][1], b[0][2] + sz * b[1][2]]
                    for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1))]
        xs, ys = [p[0] for p in outline], [p[1] for p in outline]
        print(f"The Shade {ahead} ahead: on screen x {min(xs):+.3f} to {max(xs):+.3f}, y {min(ys):+.3f} to {max(ys):+.3f} "
              "(shares of the screen's height)")
        print(f"  his root {k.v3(on_screen([0, 3, 0], cam))['Vector3']}, his head {k.v3(on_screen([0, 4.5, 0], cam))['Vector3']}")
        for hit, f in HITS.items():
            cells = []
            for name, p in n[f].items():
                s = on_screen(p, cam)
                cells.append(f"{name} ({s[0]:+.3f},{s[1]:+.3f}){' hidden' if covered(p, cam, boxes) else ''}")
            print(f"  {hit} (frame {f}): " + "; ".join(cells))


HEADINGS = (215, 145, 285, 28)  # the replay's camera, ±70 round the fight (Faber's takes), and his clip's review camera

# --- the rows: the hero is the crack --------------------------------------------------------------------------------
# Research's feel line (AR26, signed 08:06): each blow cracks Storm on the touch, short and hard; the third earths it in
# one brief spit of light along the ground; contained, earthed, never a spray; no ring and no hold (Ground Wire's).
# Hits 1 and 2: a jagged trunk at the touch forks into a wide V opening upward, so from the game's framing (heading 215
# or its mirror) the tips come out beside the Shade's shoulders, which hide the touch itself. Hit 3: one jagged spit
# along the street from the butt's foot, under the Shade's feet and out past its heels. Each line is Beams end to end
# (each Beam placed at its own Low, its High the next one's Low), so it is jagged and one Beam wide.
# DESIGN seeds, frames after the hit's beat on the action's clock (so a hitstop holds the crack lit), tuned live.
GREY = "fx_beam"
WHITE = {"Color3": [255, 255, 255]}
USED = ("fx_beam", "fx_spark")
SEED = 26  # the kinks' dice: fixed, so the file is the same each run
DRAW = 1.6  # frames for the crack to run from the touch to its tips: fast at first (a snap)
WHOLE = 4  # it holds whole to here; the re-strike's new kinks jump in on this frame, a little wider
GONE = 9  # thinned out and gone: 0.15 s, the hitstop's hold on top
SPIT_DRAW, SPIT_GONE = 3, 10  # the spit runs out over three frames, and is gone by ten
TRUNK = 0.45  # studs up from the touch to the fork
BRANCH = 2.1  # studs, each branch of the V, in two steps
SPREAD = (32, 148)  # the branches' directions across his line, degrees from his right toward up (measured: these escape
#                     the Shade's outline soonest from heading 215 and its mirror)
KINK = 0.2  # studs, the most a joint stands off the straight line
WIDTH = {"Trunk": 0.26, "Branch": 0.19, "Spit": 0.24}  # studs across at their foot; a line's last step tapers
SPIT = {"past": 1.6, "up": 0.08}  # studs past the Shade's heels the spit runs, and its height over the street
HEELS = 0.52  # the Shade's leg's half depth: its heels this far behind its centre


def kinked(points, rng, plane):
    """The joints between the line's ends stood off it, each its own way within `plane` (two units), at most KINK."""
    out = [points[0]]
    for p in points[1:-1]:
        a = rng.uniform(0, 2 * math.pi)
        r = KINK * rng.uniform(0.55, 1.0)
        out.append(k.add(p, k.add(k.mul(plane[0], math.cos(a) * r), k.mul(plane[1], math.sin(a) * r))))
    return out + [points[-1]]


def along(a, b, steps):
    return [k.add(a, k.mul(k.sub(b, a), i / steps)) for i in range(steps + 1)]


def line_rows(name, hit, takes, starts, width, life):
    """One jagged line as Beams end to end: takes[0] its joints from the beat, takes[1] (if any) from WHOLE, the
    re-strike's. starts[i]: the frame its i-th step shows. The last joint gets a blank Beam, only for its place."""
    draw_to, whole, gone = life
    rows = {}
    count = len(takes[0]) - 1
    for i in range(count + 1):
        row_name = f"{name}{i + 1}" if i < count else f"{name}End"
        at = [[0, k.v3(takes[0][i]), "Linear"]]
        if len(takes) > 1:
            at += [[whole - 0.05, k.v3(takes[0][i]), "Linear"], [whole, k.v3(takes[1][i])]]
        else:
            at[0] = [0, k.v3(takes[0][i])]
        row = {"Kind": "Beam", "Image": GREY, "Grey": GREY, "Color": WHITE, "From": hit,
               "Beam": {"FaceCamera": True, "TextureMode": "Stretch", "TextureLength": 1, "TextureSpeed": 0,
                        "LightEmission": 1, "LightInfluence": 0, "Brightness": 3, "Segments": 1},
               "Tracks": {"At": at, "Foot": [[0, 0]]}}  # its Low is its own place
        if i < count:
            row["High"] = f"{name}{i + 2}.Low" if i + 1 < count else f"{name}End.Low"
            w = width * (1 - 0.18 * i / max(count - 1, 1))
            s = round(starts[i], 2)
            row["Tracks"]["Width"] = [[s, round(w * 0.7, 3), "Quart Out"], [s + 1, w, "Linear"]] + (
                [[whole - 0.05, w, "Linear"], [whole, round(w * 1.25, 3), "Quad In"]] if len(takes) > 1 else
                [[whole, w, "Quad In"]]) + [[gone, round(w * 0.45, 3)]]
            row["Tracks"]["Transparency"] = [[s, 0, "Linear"], [whole + 0.5, 0, "Quad In"], [gone, 1]]
            if i == count - 1:
                row["Taper"] = 0.25
            row["Why"] = f"{name}, step {i + 1} of {count}"
        else:
            row["Tracks"]["Width"] = [[0, 0]]
            row["Why"] = f"{name}'s tip: a place for the step before it, never shown"
        rows[row_name] = row
    return rows


def crack(hit, touch, rng, up_way):
    """A trunk from the touch up `up_way`, forking into the V. Two takes of the kinks: the strike and the re-strike."""
    across = [1.0, 0.0, 0.0]
    fork = k.add(touch, k.mul(up_way, TRUNK))
    plane = (across, [0.0, 0.0, 1.0])  # the kinks stand off in his right and along his line, so every camera sees some
    takes = {"Trunk": [], "L": [], "R": []}
    for _ in range(2):
        takes["Trunk"].append(kinked(along(touch, fork, 2), rng, plane))
        for side, deg in (("R", SPREAD[0]), ("L", SPREAD[1])):
            r = math.radians(deg)
            way = k.unit(k.add(k.mul(across, math.cos(r)), k.mul(up_way, math.sin(r))))
            tip = k.add(fork, k.mul(way, BRANCH))
            takes[side].append(kinked(along(fork, tip, 2), rng, (plane[1], k.unit([-way[1], way[0], 0.0]))))
    life = (DRAW, WHOLE, GONE)
    third = DRAW / 3
    rows = line_rows(f"{hit}Trunk", hit, takes["Trunk"], [0, third * 0.5], WIDTH["Trunk"], life)
    for side in ("L", "R"):
        rows.update(line_rows(f"{hit}{side}", hit, takes[side], [third, third * 2], WIDTH["Branch"], life))
    rows[f"{hit}Light"] = {"Kind": "Light", "From": hit, "Range": 8, "Color": WHITE,
                           "Why": "the crack lights what it touches, for a breath",
                           "Tracks": {"At": [[0, k.v3(k.add(touch, k.mul(up_way, 0.3)))]],
                                      "Brightness": [[0, 5, "Quart Out"], [7, 0]]}}
    return rows, takes


def spit(n, ahead, rng):
    """Hit 3: one jagged spit along the street from the butt's foot, ahead under the Shade, out past its heels."""
    foot = [n[60]["Butt"][0], SPIT["up"], n[60]["Butt"][2]]
    end = [0.0, SPIT["up"], -(ahead + HEELS + SPIT["past"])]
    steps = max(3, round(k.length(k.sub(end, foot)) / 1.1))
    way = k.unit(k.sub(end, foot))
    take = kinked(along(foot, end, steps), rng, ([-way[2], 0.0, way[0]], [-way[2], 0.0, way[0]]))
    starts = [SPIT_DRAW * (1 - (1 - i / steps) ** 2) * 0.9 for i in range(steps)]  # Quad Out: fast from the butt
    rows = line_rows("Hit3Spit", "Hit3", [take], starts, WIDTH["Spit"], (SPIT_DRAW, SPIT_DRAW + 1, SPIT_GONE))
    rows["Hit3Light"] = {"Kind": "Light", "From": "Hit3", "Range": 10, "Color": WHITE,
                         "Why": "the drive's foot lit as it earths",
                         "Tracks": {"At": [[0, k.v3(k.add(foot, [0, 0.6, 0]))]],
                                    "Brightness": [[0, 6, "Quart Out"], [9, 0]]}}
    return rows, take


def discs():
    """The three white discs tick on each hit: one row for the combo, so no hit's last key holds them against the next."""
    b = HITS
    keys = []
    for hit, hot in (("Hit1", 2.4), ("Hit2", 2.4), ("Hit3", 3.0)):
        t = b[hit] - b["Hit1"]
        if keys:
            keys.append([t - 0.05, 0, "Linear"])
        keys += [[t, hot, "Quad Out"], [t + 8, 0, "Linear"]]
    return {"Kind": "Glow", "Part": [SPEAR], "From": "Hit1", "Tracks": {"Glow": keys},
            "Why": "the discs tick hot on each blow and cool in eight frames (the recipe's hot 2.5): the spear carries it"}


def effect(ahead=SPACING):
    n = measure(list(HITS.values()))
    rng = __import__("random").Random(SEED)
    front = ahead - 0.74  # the Shade's chest's face toward him
    touch1 = [0.0, n[21]["Butt"][1], -(front - 0.3)]  # between the shaft across his chest and the Shade's chest
    touch2 = [n[36]["Butt"][0], n[36]["Butt"][1], -(front - 0.4)]  # the butt's top as it comes up under the chest,
    #   set before the Shade's mask, which stands 0.2 proud of its chest
    rows, lines = {"Discs": discs()}, {}
    for hit, touch, lean in (("Hit1", touch1, 0.12), ("Hit2", touch2, 0.2)):
        up_way = k.unit([0.0, 1.0, lean])  # the V leans back toward him, off the Shade's face
        r, takes = crack(hit, touch, rng, up_way)
        rows.update(r)
        lines[hit] = takes
    r, take = spit(n, ahead, rng)
    rows.update(r)
    lines["Hit3"] = {"Spit": [take]}
    return {"Schema": "rows/1", "Effect": ACTION,
            "Why": "Watt's basic attack, the grey block (AR26; research's feel line, 08:06): on hits 1 and 2 a crack "
                   "of Storm forks off the touch, on hit 3 one spit runs along the street from the butt's foot. On the "
                   f"action's clock, so a hitstop holds it lit. The touches are placed for the Shade {ahead} ahead, his "
                   "fighting spacing. Written by tools/blender/watt_combo_fx.py.",
            "Area": 1, "Grey": True, "Action": ACTION, "Rows": rows}, lines


def seen(lines, ahead=SPACING, samples=12):
    """Studs of each line, whole (the first take), that the Shade doesn't cover, from each of HEADINGS."""
    boxes = shade_boxes(ahead)
    out = {}
    for hit, parts in lines.items():
        for part, takes in parts.items():
            pts = takes[0]
            for h in HEADINGS:
                cam = camera(ahead, h)
                total = 0.0
                for a, b in zip(pts, pts[1:]):
                    step = k.length(k.sub(b, a)) / samples
                    total += sum(step for i in range(samples)
                                 if not covered(k.add(a, k.mul(k.sub(b, a), (i + 0.5) / samples)), cam, boxes))
                out.setdefault((hit, part), []).append((h, total, sum(k.length(k.sub(b, a)) for a, b in zip(pts, pts[1:]))))
    return out


AHEADS = (SPACING, SPACING + 0.4, SPACING + 0.8)  # his spacing, and the Shade pushed back by hits 1 and 2 (fixed rows)
TIP_MARGIN = 0.1  # studs: a tip's nearest to a face (the guard's margin; a line tapers to its point)
FORK_MARGIN = 0.1 + WIDTH["Branch"] / 2  # and the fork's, where the branches start at their full width


def crack_points(takes):
    """Every point of a crack's lines, each take, every 0.05 studs."""
    return [q for part in takes.values() for pts in part for a, b in zip(pts, pts[1:]) for q in ct.along(a, b)]


def ends(takes):
    """A crack's ends, each take: its forks (each branch's first joint) and its tips. The trunk's root is the touch."""
    every = [pts for side in ("L", "R") for pts in takes[side]]
    return [pts[0] for pts in every], [pts[-1] for pts in every]


def into(lines, waiting=None):
    """Rule 4 for a crack, on the content check's word (2026-11-17), against every target (combo_targets), each spaced
    by its depth, at his spacing and pushed back: no tip comes within TIP_MARGIN of a face and no fork within
    FORK_MARGIN, by its triangles; no end and no point of a line is inside the body. A branch that passes before a
    mask on its way out is light seen across the body, and passes. A target the game doesn't have yet goes in
    `waiting`."""
    bad, game = [], ct.in_game()
    for ahead in AHEADS:
        for hit in ("Hit1", "Hit2"):
            (forks, tips), every = ends(lines[hit]), crack_points(lines[hit])
            for name in ct.targets():
                at = ct.on_face(name, ahead)
                body, _ = ct.placed(name, at, "body")
                got = []
                p = ct.near_face(tips, name, at, TIP_MARGIN) or ct.near_face(forks, name, at, FORK_MARGIN)
                if p:
                    got.append(f"an end lies on {name}'s face at ({p[0]:.2f}, {p[1]:.2f}, {p[2]:.2f})")
                p = next((q for q in every if ct.inside(q, body, 0.0)), None)
                if p:
                    got.append(f"a line enters {name} at ({p[0]:.2f}, {p[1]:.2f}, {p[2]:.2f})")
                got = [f"{hit} {x} (the target {ahead} ahead)" for x in got]
                if waiting is not None and name not in game:
                    waiting += got
                else:
                    bad += got
    return bad


def write_rows(out):
    read_action()
    e, lines = effect()
    waiting = []
    problems = k.check(e, USED) + into(lines, waiting)
    if problems:
        raise SystemExit("the rows don't pass their own check:\n  " + "\n  ".join(problems))
    out.mkdir(parents=True, exist_ok=True)
    (out / f"{ACTION}.rows.json").write_text(json.dumps(e, indent=1) + "\n", encoding="utf-8")
    print(f"Written to {out}: {ACTION} ({len(e['Rows'])} rows)")
    print(f"  no end of the crack lies on a target's face or body, and no line enters one, at "
          f"{', '.join(str(a) for a in AHEADS)} ahead (each target spaced by its depth): {', '.join(ct.in_game())}")
    for x in waiting:
        print(f"  waits, not in the game yet (its enemy joins once this passes): {x}")
    for ahead in AHEADS:
        today = sorted({name for hit in ("Hit1", "Hit2")
                        for name in ct.root_to_root(crack_points(lines[hit]), ahead, 0.0, ct.in_game())})
        print(f"  as the game stands, root to root at {ahead}: the crack enters {', '.join(today) or 'nothing'}")
    for ahead in (SPACING, SPACING + 0.8):
        print(f"  the Shade {ahead} ahead: studs seen of each line, whole, by heading (of its length)")
        for (hit, part), cells in seen(effect(ahead)[1], ahead).items():
            print(f"    {hit} {part:5s} " + "  ".join(f"{h}: {s:.1f}" for h, s, _ in cells) + f"  (of {cells[0][2]:.1f})")


def escape(at, way, cam, boxes, longest=4.0, step=0.05):
    """Studs along `way` from `at` before a point there is no longer covered by the Shade (None if never)."""
    for i in range(1, int(longest / step) + 1):
        if not covered(k.add(at, k.mul(way, i * step)), cam, boxes):
            return i * step
    return None


def escapes(at, plane_x, plane_y, ahead=SPACING):
    """For lines out from `at` every 30 degrees in the plane of the two units, from each of HEADINGS: the studs before
    each comes out from behind the Shade ('-' never within 4)."""
    boxes = shade_boxes(ahead)
    for h in HEADINGS:
        cam = camera(ahead, h)
        cells = []
        for a in range(0, 360, 30):
            r = math.radians(a)
            way = k.unit(k.add(k.mul(plane_x, math.cos(r)), k.mul(plane_y, math.sin(r))))
            e = 0.0 if not covered(at, cam, boxes) else escape(at, way, cam, boxes)
            cells.append(f"{a}:{'-' if e is None else f'{e:.1f}'}")
        print(f"    heading {h:3d}: " + " ".join(cells))


def main():
    if sys.argv[1:2] == ["screen"]:
        screen()
        n = measure(list(HITS.values()))
        front = SPACING - 0.74  # the Shade's chest's face toward him
        touches = {
            "Hit1, the shaft across his chest, at his middle": [0.0, n[21]["Butt"][1], -front],
            "Hit2, the butt up under the chest": [n[36]["Butt"][0], n[36]["Butt"][1], -front],
            "Hit3, the butt's foot in the street": n[60]["Butt"],
        }
        for name, at in touches.items():
            print(f"{name} {k.v3(at)['Vector3']}: in the plane across his line (0 to his right, 90 up)")
            escapes(at, [1, 0, 0], [0, 1, 0])
        print("Hit3 along the street (0 to his right, 90 ahead of him)")
        escapes(n[60]["Butt"], [1, 0, 0], [0, 0, -1])
        return
    if sys.argv[1:2] == ["measure"]:
        act = read_action()
        n = measure()
        print(f"beats {act['beats']}, reach {act['reach']}, range {act['range']}")
        last = None
        for f, p in n.items():
            speed = k.length(k.sub(p["Blade"], last)) * 60 if last else 0.0
            last = p["Blade"]
            mark = next((h for h, v in HITS.items() if v == f), "")
            print(f"{f:3d} {mark:4s} " + " ".join(f"{name}=({v[0]:+.2f},{v[1]:+.2f},{v[2]:+.2f})" for name, v in p.items())
                  + f"  blade {speed:5.1f} st/s")
        print("(his root's frame, y from the floor: x right, z back; the Shade stands at -z)")
        return
    if sys.argv[1:2] == ["rows"] and len(sys.argv) > 2:
        write_rows(Path(sys.argv[2]))
        return
    print(__doc__)
    sys.exit(2)


if __name__ == "__main__":
    main()
