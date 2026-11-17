"""Kirra's basic attack, its look as rows (AR26, Kirra fifth; /ga-action steps 1 and 3; AR8, "The method").

py tools/blender/kirra_combo_fx.py measure
py tools/blender/kirra_combo_fx.py sweeps
py tools/blender/kirra_combo_fx.py rows build/handoff/Kirra/fx

Plain Python, no Blender. Its numbers come from the delivered clip (build/handoff/Kirra/clips/Kirra_Combo.json, the
Transforms the game plays) on the recipe's blade joints, and from the action's own row (read only:
src/shared/Definitions/Actions.luau, KirraCombo's Beats).
- measure: each blade's grip and point in her root's frame through the clip, with the points' speed.
- sweeps: each cut's path round its beat, where it crosses the Shade's front, and what the game's camera sees of it.
- rows: the grey block's rows, checked by rule 4's guard against every target (combo_targets), with what each camera
  sees of the cuts.
"""
import json
import math
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kirra_scarf_step_fx as k  # noqa: E402  (the CFrame sums, the Track reader, the rows file check)
import watt_combo_fx as w  # noqa: E402  (the game's camera, the Shade's boxes, what it covers: AR26's first attack)
import combo_targets as ct  # noqa: E402  (every target the cuts land on, and rule 4's guards against them)

ROOT = Path(__file__).resolve().parents[2]
RECIPE = ROOT / "build" / "handoff" / "Kirra" / "Kirra.recipe.json"
CLIP = ROOT / "build" / "handoff" / "Kirra" / "clips" / "Kirra_Combo.json"
ACTIONS = ROOT / "src" / "shared" / "Definitions" / "Actions.luau"  # read only
ACTION = "KirraCombo"
BEATS = {"Dash": 0, "Hit1": 12, "Hit2": 26, "Hit3": 56, "Sheathe": 64}  # the clip's markers, and the action's Beats
HITS = ("Hit1", "Hit2", "Hit3")
ROOT_HEIGHT = 3.0  # R6: the HumanoidRootPart's centre over the floor
BLADES = {"R": ("Kirra_BladeR", "TipR"), "L": ("Kirra_BladeL", "TipL")}
SPACING = 3.5  # studs, her root to the target's once the dash has brought her in (Moves.Dash.Gap, Rook's spacing)


def read_action():
    text = ACTIONS.read_text(encoding="utf-8")
    start = text.index(f'Id = "{ACTION}"')
    block = text[start:text.index("Id = ", start + 10)]
    beats = {n: round(float(v) * 60) for n, v in re.findall(r"(\w+) = ([\d.]+)", re.search(r"Beats = \{([^}]*)\}", block).group(1))}
    if beats != BEATS:
        raise SystemExit(f"the action's beats moved: {beats}")
    gap = float(re.search(r"Dash = \{[^}]*Gap = ([\d.]+)", block).group(1))
    if gap != SPACING:
        raise SystemExit(f"the dash's gap moved: {gap}")
    return {"beats": beats, "gap": gap}


def quat(r):
    """A rotation's rows as a unit quaternion (w, x, y, z)."""
    t = r[0][0] + r[1][1] + r[2][2]
    if t > 0:
        s = math.sqrt(t + 1) * 2
        q = [s / 4, (r[2][1] - r[1][2]) / s, (r[0][2] - r[2][0]) / s, (r[1][0] - r[0][1]) / s]
    elif r[0][0] > r[1][1] and r[0][0] > r[2][2]:
        s = math.sqrt(1 + r[0][0] - r[1][1] - r[2][2]) * 2
        q = [(r[2][1] - r[1][2]) / s, s / 4, (r[0][1] + r[1][0]) / s, (r[0][2] + r[2][0]) / s]
    elif r[1][1] > r[2][2]:
        s = math.sqrt(1 + r[1][1] - r[0][0] - r[2][2]) * 2
        q = [(r[0][2] - r[2][0]) / s, (r[0][1] + r[1][0]) / s, s / 4, (r[1][2] + r[2][1]) / s]
    else:
        s = math.sqrt(1 + r[2][2] - r[0][0] - r[1][1]) * 2
        q = [(r[1][0] - r[0][1]) / s, (r[0][2] + r[2][0]) / s, (r[1][2] + r[2][1]) / s, s / 4]
    n = math.sqrt(sum(c * c for c in q))
    return [c / n for c in q]


def rows_of(q):
    w, x, y, z = q
    return [[1 - 2 * (y * y + z * z), 2 * (x * y - w * z), 2 * (x * z + w * y)],
            [2 * (x * y + w * z), 1 - 2 * (x * x + z * z), 2 * (y * z - w * x)],
            [2 * (x * z - w * y), 2 * (y * z + w * x), 1 - 2 * (x * x + y * y)]]


def lerp_pose(a, b, u):
    """Two of a clip's 12-number poses, `u` of the way: CFrame:Lerp, as the player blends one frame into the next (the
    position straight, the rotation by the shorter arc)."""
    (ra, pa), (rb, pb) = k.cframe(a), k.cframe(b)
    qa, qb = quat(ra), quat(rb)
    d = sum(qa[i] * qb[i] for i in range(4))
    if d < 0:
        qb, d = [-c for c in qb], -d
    if d > 0.9995:
        q = [qa[i] + (qb[i] - qa[i]) * u for i in range(4)]
    else:
        th = math.acos(d)
        q = [(math.sin((1 - u) * th) * qa[i] + math.sin(u * th) * qb[i]) / math.sin(th) for i in range(4)]
    n = math.sqrt(sum(c * c for c in q))
    r = rows_of([c / n for c in q])
    p = [pa[j] + (pb[j] - pa[j]) * u for j in range(3)]
    return p + r[0] + r[1] + r[2]


def poses_at(clip, f):
    """The clip's poses at frame `f`, a whole frame or between two."""
    frames = clip["Frames"]
    lo = max(0, min(len(frames) - 1, math.floor(f)))
    u = f - lo
    if u < 1e-9 or lo + 1 >= len(frames):
        return frames[lo]["Poses"]
    a, b = frames[lo]["Poses"], frames[lo + 1]["Poses"]
    return {j: lerp_pose(a[j], b[j], u) for j in a}


def measure(frames=None):
    """Each blade in her root's frame, frame by frame (x right, y from the floor, z back): its grip's middle (the
    joint's pivot) and its point. A frame between two is blended as the player blends it."""
    recipe = json.loads(RECIPE.read_text(encoding="utf-8"))
    clip = json.loads(CLIP.read_text(encoding="utf-8"))
    marks = {m["Name"]: round(m["T"] * clip["Fps"]) for m in clip["Markers"]}
    if marks != BEATS:
        raise SystemExit(f"the clip's markers moved: {marks}")
    points = {p["name"]: p["at"] for p in recipe["points"]}
    pieces = {p["name"]: p for p in recipe["pieces"]}
    torso_rest = [0.0, ROOT_HEIGHT, 0.0]
    out = {}
    for f in frames if frames is not None else range(len(clip["Frames"])):
        poses = poses_at(clip, f)
        torso = k.compose(k.compose(k.R6_ROOT, k.cframe(poses["Torso"])), k.inverse(k.R6_ROOT))
        out[f] = {}
        for side, (piece, tip) in BLADES.items():
            p = pieces[piece]
            if p["on"] != "Torso":
                raise SystemExit(f"{piece} isn't on the Torso")
            joint = k.compose(k.compose(torso, k.moved(k.sub(p["pivot"], torso_rest))), k.cframe(poses[piece]))
            grip = k.add(joint[1], [0, ROOT_HEIGHT, 0])
            point = k.add(k.compose(joint, k.moved(k.sub(points[tip], p["pivot"])))[1], [0, ROOT_HEIGHT, 0])
            out[f][side] = {"Grip": grip, "Point": point}
    return out


PUSH = 0.4  # studs: hits 1 and 2 push the Shade back (KirraCombo's Hits, read in read_action), so hit 2 meets it at 3.9
CLEAR = 0.18  # studs: a cut's line stands this far before the target's torso face, never on it (0.1, and half its width)
WHO = {"Hit1": ("R",), "Hit2": ("L",), "Hit3": ("R", "L")}  # the blade that cuts on each beat (the measure's)


def ahead_at(hit):
    """Where the Shade stands on a beat, root to root, before that beat's own push."""
    return SPACING + PUSH * HITS.index(hit)


def crossings(hit, side, before=3.0, after=3.0, step=0.05):
    """Where a blade crosses the plane CLEAR before the Shade's torso face round a beat: (frame, the point there, how
    far along the blade from the grip, 0 to 1), each time the blade spans the plane, every `step` of a frame."""
    plane = -ahead_at(hit) + ct.FRONT + CLEAR
    beat = BEATS[hit]
    ts = [beat - before + i * step for i in range(int((before + after) / step) + 1)]
    n = measure(ts)
    out = []
    for t in ts:
        g, p = n[t][side]["Grip"], n[t][side]["Point"]
        if (g[2] - plane) * (p[2] - plane) < 0:
            u = (plane - g[2]) / (p[2] - g[2])
            out.append((t, k.add(g, k.mul(k.sub(p, g), u)), u))
    return out


# --- the look (research's line 5): the dash's streak, two crisp cuts that snap shut, the second worn as an X, the rise ---

GREY = "fx_beam"
WHITE = {"Color3": [255, 255, 255]}
USED = ("fx_beam",)
LEGS_TOP = 2.0  # studs up: the Shade's and the Lamplighter's legs' top at their recipe's size (times its Scale)
TOP_Y = 3.3  # a line's top: lifted to the elite's waist, 3.45 draws over its arm's mask from its left (the guard)
BOTTOM_Y = LEGS_TOP + 0.05  # a line's foot: on the torso, never before the thighs (the content check, 10:50)
CROSS_Y = (BOTTOM_Y + TOP_Y) / 2  # where the X's lines cross: the torso's middle
LINE_WIDTH = 0.1  # studs: crisp, never swelling in its middle (the content check's condition)
SHOW = 2  # frames after its beat a cut shows: the blade is past the plane by then (sweeps: 13.2 for cut 1)
HOLD = 2  # frames it stays crisp
SHUT = 4  # frames it takes to snap shut
UNSEEN = [[0, 1, "Linear"], [SHOW - 1, 1, "Linear"]]  # a cut's transparency from its beat: nothing until the blade is past
UNSEEN_WIDTH = [[0, 0, "Linear"], [SHOW - 1, 0, "Linear"]]
UNSEEN_LIGHT = [[0, 0, "Linear"], [SHOW - 1, 0, "Linear"]]
WEAR = {"width": 0.035, "transparency": 0.4}  # the X, worn faint after it snaps thin
FLINCH_END = 16  # frames after hit 2: gone with an ordinary Shade's flinch (hitstop and Combat.Flinch's 0.28 s)
RISE = (52, 60)  # frames: the blades rise (measure: both points from 0.76 to 6.10 up over 52 to 56), lit
KNOT = [0.0, 0.2, 0.55]  # the streak's point, from her root: behind her back, under every face's foot
BEAM = {"FaceCamera": True, "TextureMode": "Stretch", "TextureLength": 1, "TextureSpeed": 0, "LightEmission": 1,
        "LightInfluence": 0, "Brightness": 3, "Segments": 1}
MARGIN = 0.1 + LINE_WIDTH / 2  # studs: no line nearer a target's part or face than this


def angle_of(hit, side):
    """The cut's direction in the plane, from its blade's crossings: unit (x, y), pointing up."""
    c = crossings(hit, side)
    a, b = c[0][1], c[-1][1]
    d = k.unit([a[0] - b[0], a[1] - b[1], 0.0])
    return d if d[1] > 0 else k.mul(d, -1)


def cut_line(d, plane):
    """A cut's straight line at the blade's angle `d`, moved onto the Shade's middle: through (0, CROSS_Y), from
    BOTTOM_Y up to TOP_Y, in the plane `plane` before the torso face. Its foot and top, in her foot's frame."""
    lo = [d[0] * (BOTTOM_Y - CROSS_Y) / d[1], BOTTOM_Y, plane]
    hi = [d[0] * (TOP_Y - CROSS_Y) / d[1], TOP_Y, plane]
    return lo, hi


def plane_of(hit):
    return -ahead_at(hit) + ct.FRONT + CLEAR


def from_root(p):
    return [p[0], p[1] - ROOT_HEIGHT, p[2]]


def toward(a, b, u):
    return k.add(a, k.mul(k.sub(b, a), u))


def line(name, on, lo, hi, width, transparency, ends=None, why=""):
    """One straight Beam from lo to hi (her foot's frame) on the held point `on`: its row at lo, a blank end row at
    hi. `width` and `transparency` are its keys; `ends` (frame, lo, hi, ease) move its ends."""
    at_lo, at_hi = [[0, k.v3(from_root(lo))]], [[0, k.v3(from_root(hi))]]
    for f, a, b, ease in ends or []:
        at_lo[-1] = at_lo[-1][:2] + ([ease] if ease else [])
        at_hi[-1] = at_hi[-1][:2] + ([ease] if ease else [])
        at_lo.append([f, k.v3(from_root(a))])
        at_hi.append([f, k.v3(from_root(b))])
    return {
        name: {"Kind": "Beam", "On": on, "Image": GREY, "Grey": GREY, "Color": WHITE, "Beam": BEAM, "High": f"{name}End.Low",
               "Why": why, "Tracks": {"At": at_lo, "Foot": [[0, 0]], "Width": width, "Transparency": transparency}},
        f"{name}End": {"Kind": "Beam", "On": on, "Image": GREY, "Grey": GREY, "Color": WHITE, "Beam": BEAM,
                       "Why": f"{name}'s top: a place for it, never shown",
                       "Tracks": {"At": at_hi, "Foot": [[0, 0]], "Width": [[0, 0]]}},
    }


def held(name, hit):
    return {name: {"Kind": "Point", "From": hit, "Body": "HumanoidRootPart", "Hold": True,
                   "Why": f"her root as it stands on {hit}, kept there: the cut stays where she cut",
                   "Tracks": {"At": [[0, k.v3([0, 0, 0])]]}}}


def snapping(lo, hi):
    """A cut that shows crisp at SHOW, holds, and snaps shut: its width to nothing and its ends 20% in to its middle."""
    mid = toward(lo, hi, 0.5)
    shut = SHOW + HOLD + SHUT
    width = UNSEEN_WIDTH + [[SHOW, LINE_WIDTH, "Linear"], [SHOW + HOLD, LINE_WIDTH, "Quad In"], [shut, 0]]
    transparency = UNSEEN + [[SHOW, 0, "Linear"], [shut - 1, 0, "Linear"], [shut, 1]]
    ends = [(SHOW + HOLD, lo, hi, "Quad In"), (shut, toward(lo, mid, 0.2), toward(hi, mid, 0.2), None)]
    return width, transparency, ends


def worn():
    """A line of the X: crisp at SHOW, snapped thin, worn faint, and gone by FLINCH_END: while an ordinary Shade
    flinches it can't step into it (the content check's way b, 10:50)."""
    thin = SHOW + HOLD + SHUT
    width = UNSEEN_WIDTH + [[SHOW, LINE_WIDTH, "Linear"], [SHOW + HOLD, LINE_WIDTH, "Quad In"], [thin, WEAR["width"], "Linear"],
             [FLINCH_END, WEAR["width"]]]
    transparency = UNSEEN + [[SHOW, 0, "Linear"], [SHOW + HOLD, 0, "Quad In"], [thin, WEAR["transparency"], "Linear"],
                    [FLINCH_END - 3, WEAR["transparency"], "Quad In"], [FLINCH_END, 1]]
    return width, transparency


def effect():
    """The rows, and every line in her foot's frame on its beat (for the guard and the seen table)."""
    rows, lines = {}, {}
    d1, d2 = angle_of("Hit1", "R"), angle_of("Hit2", "L")
    # the dash's streak: a trail behind her at the knot's height, closing onto her as she stops
    rows["Streak"] = {"Kind": "Beam", "Body": "HumanoidRootPart", "Image": GREY, "Grey": GREY, "Color": WHITE,
                      "Beam": dict(BEAM, Segments=6), "Trail": {"Back": 0.3, "Beyond": 0.4},
                      "Why": "the dash's thin streak, behind her back (the scarf's colour at the finish)",
                      "Tracks": {"At": [[0, k.v3(KNOT)]], "Lag": [[0, 5]],
                                 "Width": [[1, 0.12, "Linear"], [9, 0.06, "Quad In"], [14, 0.0]],
                                 "Transparency": [[1, 0.1, "Linear"], [9, 0.25, "Quad In"], [14, 1]]}}
    lines["Streak"] = [[(KNOT[0], KNOT[1] + ROOT_HEIGHT, KNOT[2] + 3.5), (KNOT[0], KNOT[1] + ROOT_HEIGHT, KNOT[2])]]
    # cut 1, on hit 1
    rows.update(held("Cut1At", "Hit1"))
    lo, hi = cut_line(d1, plane_of("Hit1"))
    w1, t1, e1 = snapping(lo, hi)
    rows.update(line("Cut1", "Cut1At", lo, hi, w1, t1, e1, "cut 1: a crisp line at the right blade's angle, snapping shut"))
    rows["Cut1Light"] = {"Kind": "Light", "On": "Cut1At", "Range": 6, "Color": WHITE,
                         "Why": "the cut's light, which rims the Shade where the line is behind it",
                         "Tracks": {"At": [[0, k.v3(from_root(toward(lo, hi, 0.5)))]],
                                    "Brightness": UNSEEN_LIGHT + [[SHOW, 3, "Quart Out"], [SHOW + HOLD + SHUT, 0]]}}
    lines["Cut1"] = [(lo, hi)]
    # cut 2 on hit 2, with cut 1's line again beside it: the X, worn faint while the Shade flinches
    rows.update(held("Cut2At", "Hit2"))
    x = []
    for name, d, why in (("Cut2", d2, "cut 2: a crisp line at the left blade's angle"),
                         ("Cross", d1, "cut 1's line again, crossing cut 2: the X")):
        lo, hi = cut_line(d, plane_of("Hit2"))
        wn, tn = worn()
        rows.update(line(name, "Cut2At", lo, hi, wn, tn, None, why + ", snapped thin, worn faint, gone with the flinch"))
        x.append((lo, hi))
    rows["Cut2Light"] = {"Kind": "Light", "On": "Cut2At", "Range": 6, "Color": WHITE,
                         "Why": "the X's light on hit 2, which rims the Shade where the lines are behind it",
                         "Tracks": {"At": [[0, k.v3(from_root([0.0, CROSS_Y, plane_of("Hit2")]))]],
                                    "Brightness": UNSEEN_LIGHT + [[SHOW, 3.5, "Quart Out"], [SHOW + HOLD + SHUT, 0]]}}
    lines["X"] = x
    # the rise: a light on each blade's tip as it climbs, which flashes up her blades and the Shade's front; no line
    # (a trail past the masks' foot draws over a face from the side: the guard, 10:55)
    for side, (_, tip) in BLADES.items():
        rows[f"Rise{side}"] = {"Kind": "Light", "From": "Dash", "Body": tip, "Range": 7, "Color": WHITE,
                               "Why": f"the rise: the {'right' if side == 'R' else 'left'} blade's tip flashes as it climbs",
                               "Tracks": {"At": [[RISE[0], k.v3([0, 0, 0])]],
                                          "Brightness": [[RISE[0], 0, "Quad In"], [RISE[0] + 3, 5, "Quart Out"],
                                                         [RISE[1], 0]]}}
    return {"Schema": "rows/1", "Effect": ACTION,
            "Why": "Kirra's basic attack (KirraCombo), the grey block (AR26; research's feel line, 08:06): the dash's "
                   "streak, two crisp cuts that snap shut, the second worn as an X while the Shade flinches, and the "
                   "rise flashing up her blades. Written by tools/blender/kirra_combo_fx.py.",
            "Area": 1, "Grey": True, "Action": ACTION, "Rows": rows}, lines


AHEAD = {"Streak": "Hit1", "Cut1": "Hit1", "X": "Hit2"}  # where the Shade stands on each line's beat
CUTS = ("Cut1", "X")  # lifted to a bigger target's waist (the ask): the streak rides her, not the target


def lift(name):
    """How far a cut is lifted on a target: to its legs' top times its Scale (the waist ask; 0 on the ordinary Shade)."""
    return LEGS_TOP * (ct.targets()[name]["scale"] - 1)


def lifted(points, name):
    return [[p[0], p[1] + lift(name), p[2]] for p in points]


def into(lines, waiting=None):
    """Rule 4 against every target (combo_targets), each spaced by its depth, where it stands on the line's beat, the
    cuts lifted to its waist: no point of a line within MARGIN of a part, or drawing over a face from any view, every
    0.05 studs; and no cut's foot under its legs' top (the content check, 10:50)."""
    bad = []
    for name, segs in lines.items():
        ahead = ahead_at(AHEAD[name])
        fit = lifted if name in CUTS else None
        for i, (a, b) in enumerate(segs):
            what = f"{name} line {i + 1}"
            bad += ct.rule4(ct.along(a, b), ahead, what, margin=MARGIN, waiting=waiting, fit=fit)
            if fit:
                for t, v in ct.targets().items():
                    foot, legs = min(a[1], b[1]) + lift(t), LEGS_TOP * v["scale"]
                    if foot < legs:
                        (waiting if waiting is not None and t not in ct.in_game() else bad).append(
                            f"{what}'s foot {foot:.2f} under {t}'s legs' top {legs:.2f}")
    return bad


def seen(lines, samples=24):
    """Studs of each line the ordinary Shade doesn't cover, by heading: (seen, length)."""
    out = {}
    for name in ("Cut1", "X"):
        ahead = ahead_at(AHEAD[name])
        boxes = w.shade_boxes(ahead)
        for h in w.HEADINGS:
            cam = w.camera(ahead, h)
            each = []
            for a, b in lines[name]:
                step = k.length(k.sub(b, a)) / samples
                each.append((sum(step for i in range(samples)
                                 if not w.covered(toward(a, b, (i + 0.5) / samples), cam, boxes)), step * samples))
            out.setdefault(name, []).append((h, each))
    return out


def write_rows(out):
    read_action()
    e, lines = effect()
    waiting = []
    problems = k.check(e, USED) + into(lines, waiting)
    if problems:
        raise SystemExit("the rows don't pass their own check:\n  " + "\n  ".join(problems))
    out.mkdir(parents=True, exist_ok=True)
    (out / f"{ACTION}.rows.json").write_text(json.dumps(e, indent=1) + "\n", encoding="utf-8")
    print(f"Written to {out}: {ACTION} ({len(e['Rows'])} rows), the X gone {FLINCH_END} frames after hit 2")
    print(f"  no line enters a target or draws over its face from {len(ct.VIEWS)} views, each target spaced by its "
          f"depth where it stands on the line's beat, the cuts lifted to its waist: {', '.join(ct.in_game())}")
    for x in waiting:
        print(f"  waits, not in the game yet (its enemy joins once this passes): {x}")
    for name in CUTS:
        today = sorted({t for a, b in lines[name] for t in ct.root_to_root(ct.along(a, b), ahead_at(AHEAD[name]), MARGIN,
                                                                          ct.in_game())})
        low = [t for t in ct.in_game() if min(p[1] for s in lines[name] for p in s) < LEGS_TOP * ct.targets()[t]["scale"]]
        print(f"  as the game stands (root to root, no lift): {name} enters {', '.join(today) or 'nothing'}; "
              f"its foot under the legs' top of {', '.join(low) or 'nothing'}")
    d1, d2 = angle_of("Hit1", "R"), angle_of("Hit2", "L")
    print(f"  the cuts' angles off level: {math.degrees(math.atan2(d1[1], abs(d1[0]))):.0f} and "
          f"{math.degrees(math.atan2(d2[1], abs(d2[0]))):.0f}")
    for name, cells in seen(lines).items():
        for h, each in cells:
            print(f"    {name} {h:3d}: " + "  ".join(f"{s:.2f} of {t:.2f}" for s, t in each))


def main():
    if sys.argv[1:2] == ["rows"] and len(sys.argv) > 2:
        write_rows(Path(sys.argv[2]))
        return
    if sys.argv[1:2] == ["sweeps"]:
        read_action()
        for hit, sides in WHO.items():
            for side in sides:
                c = crossings(hit, side)
                print(f"{hit} {side}: the plane {-ahead_at(hit) + ct.FRONT + CLEAR:.2f} (the Shade {ahead_at(hit)} ahead), "
                      f"{len(c)} crossings")
                for t, q, u in c[::4] + c[-1:]:
                    print(f"   {t:6.2f}  ({q[0]:+.2f}, {q[1]:+.2f}, {q[2]:+.2f})  {u:.2f} along")
        return
    if sys.argv[1:2] == ["measure"]:
        print(read_action())
        n = measure()
        last = {}
        for f, blades in n.items():
            mark = next((b for b, v in BEATS.items() if v == f), "")
            cells = []
            for side, p in blades.items():
                speed = k.length(k.sub(p["Point"], last[side])) * 60 if side in last else 0.0
                last[side] = p["Point"]
                cells.append(f"{side} grip ({p['Grip'][0]:+.2f},{p['Grip'][1]:+.2f},{p['Grip'][2]:+.2f}) "
                             f"point ({p['Point'][0]:+.2f},{p['Point'][1]:+.2f},{p['Point'][2]:+.2f}) {speed:5.1f}")
            print(f"{f:3d} {mark:7s} " + " | ".join(cells))
        print("(her root's frame, y from the floor: x right, z back; the Shade stands at -z, its chest's face "
              f"{SPACING - ct.FRONT:.2f} ahead)")
        return
    print(__doc__)


if __name__ == "__main__":
    main()
