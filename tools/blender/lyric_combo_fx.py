"""Lyric's basic attack, its look as rows (AR26, Lyric fourth; /ga-action steps 1 and 3; AR8, "The method").

py tools/blender/lyric_combo_fx.py measure
py tools/blender/lyric_combo_fx.py rows <out_dir>

Plain Python, no Blender. Its numbers come from the delivered clip (build/handoff/Lyric/clips/Lyric_Combo.json, the
Transforms the game plays) on the recipe's two speaker joints on the Torso, and from the action's own row (read only:
src/shared/Definitions/Actions.luau, LyricCombo's Beats and Range).
- measure: the two speakers' rings in her root's frame through the clip, with their speed.
- rows: LyricShots (her own rows), LyricPulse (the flight's) and LyricBurst (where it lands), schema rows/1, in grey.
"""
import json
import math
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kirra_scarf_step_fx as k  # noqa: E402  (the CFrame sums, the rows file check)
import watt_combo_fx as w  # noqa: E402  (the game's camera, the Shade's boxes, what it covers)
import combo_targets as ct  # noqa: E402  (every target the burst lands on, and rule 4's guards against them)

ROOT = Path(__file__).resolve().parents[2]
RECIPE = ROOT / "build" / "handoff" / "Lyric" / "Lyric.recipe.json"
CLIP = ROOT / "build" / "handoff" / "Lyric" / "clips" / "Lyric_Combo.json"
ACTIONS = ROOT / "src" / "shared" / "Definitions" / "Actions.luau"  # read only
ACTION = "LyricCombo"
HITS = {"Shot1": 15, "Shot2": 30, "Shot3": 60}  # the clip's markers, checked against it and against the action's Beats
FIRES = {"Shot1": ("RingR",), "Shot2": ("RingL",), "Shot3": ("RingR", "RingL")}  # the clip's own: right, left, both
SPEAKERS = {"RingR": "Lyric_SpeakerR", "RingL": "Lyric_SpeakerL"}
ROOT_HEIGHT = 3.0
APPROACH = 1.0  # Config.Combat.Approach
HEADINGS = w.HEADINGS


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
    """Each speaker's ring in her root's frame (x right, y from the floor, z back)."""
    recipe = json.loads(RECIPE.read_text(encoding="utf-8"))
    clip = json.loads(CLIP.read_text(encoding="utf-8"))
    marks = {m["Name"]: round(m["T"] * clip["Fps"]) for m in clip["Markers"]}
    if marks != HITS:
        raise SystemExit(f"the clip's markers moved: {marks}")
    pieces = {p["name"]: p for p in recipe["pieces"]}
    points = {p["name"]: p["at"] for p in recipe["points"]}
    out = {}
    for f in frames if frames is not None else range(len(clip["Frames"])):
        poses = clip["Frames"][f]["Poses"]
        torso = k.compose(k.compose(k.R6_ROOT, k.cframe(poses["Torso"])), k.inverse(k.R6_ROOT))
        out[f] = {}
        for ring, piece in SPEAKERS.items():
            if pieces[piece]["on"] != "Torso":
                raise SystemExit(f"{piece} isn't on the Torso")
            pivot = pieces[piece]["pivot"]
            joint = k.compose(k.compose(torso, k.moved(k.sub(pivot, [0.0, ROOT_HEIGHT, 0.0]))), k.cframe(poses[piece]))
            out[f][ring] = k.add(k.compose(joint, k.moved(k.sub(points[ring], pivot)))[1], [0, ROOT_HEIGHT, 0])
    return out


# --- the rows: the hero is the ring of sound, from the speaker to the burst --------------------------------------------
# Research's feel line (AR26, signed 08:06, its camera corrected 08:16): each speaker fires a pulse you can see travel,
# speaker to Shade, and it bursts there on the beat; the third, both at once, lands as two pulses crossing on the same
# frame. Her hits keep time like a song. A travelling ring of sound, never a crack in the ground; no cone (Held Note's).
# Measured (measure): each speaker drives forward into its beat (frames 10 to 14 for the right, 25 to 29 for the left,
# 53 to 59 for both) and stops on it. So the speaker's thrust launches the ring: it leaves FLIGHT frames before the beat
# and lands on it, whatever the distance, so the burst is on the beat and the hit needs no wait.
# Three parts, each where it can live:
# - LyricShots (this action's rows, in her frame): at each firing speaker, from the launch, a mouth ring and a light that
#   follow the ring's own path through the clip. The builder's Streaks stay until the pulse flies.
# - The flight: from the speaker to the target as it stands, so it can't be rows in her frame. Faber's (AR26, "Pip's
#   basic attack", the ask), in its land-on-the-beat way: LyricPulse rides its head.
# - LyricBurst (its own rows, where the pulse lands, facing the Shade's front): the ring bursts into a wide, low oval
#   before the Shade's belly, so its sides and its foot come out past the Shade's arms and legs from behind, and its top
#   stays under the lowest mask's foot (Dasher's, 3.06 up); and a light. Off the street: Ground Wire's ring is the
#   street's. LyricBurstBoth, the third: the two pulses land on the same frame, and their two ovals open crossed.
# DESIGN seeds, frames after the hit's beat (negative: before it), tuned live.
HOOP, LOOK = "FxHoop", "fx_rise_Grey"
GREY = "fx_beam"
WHITE = {"Color3": [255, 255, 255]}
USED = (HOOP, LOOK, GREY)
FLIGHT = 5  # frames from the speaker to the Shade: the pulse leaves at the beat less this, and lands on it
FACE = {"Vector3": [90, 0, 0]}  # the hoop's axis (its up) turned onto its row's -Z... its back: the band runs back to her
MOUTH = {"scale": (0.35, 0.7), "life": 5}  # the mouth ring at the speaker: studs of radius from the launch to its end
PULSE = {"scale": (0.4, 0.5), "glow": 1.5, "trail": (0.1, 2, 0.6)}  # radius at launch and landing; trail width,
#   lag, see-through
BURST = {"from": (0.9, 0.45), "to": (3.4, 0.85), "out": 6, "gone": 9, "glow": 2.0, "cross": 9}
#   the burst's oval, its half widths across and up and down (the hoop's rim is 0.7 to 1 of them): from `from` to `to`,
#   out by `out`, gone by `gone`. On the third the two are rolled `cross` degrees either way off level.
LAND, STANDOFF = 1.9, 0.4  # the pulse lands this high before the Shade's belly, whatever the spacing, and this far
#   before the torso's face: the burst's top stays under the lowest mask's foot (Dasher's, 3.06 up; 2.96 with the guard's
#   margin), seen from her side, from above
ARRIVAL = 1.2  # studs: the pulse is guarded over its last approach, where it could seem to strike the face; before
#   that it's in the open street between them (at her speaker it's hers)
INNER = 0.7  # the hoop's inner rim, of its outer (tools/blender/fx_kit.py, hoop)
CLOSE = 5.0  # studs: a Shade that has walked in on her, for the measures


def launch_path(n, ring, beat):
    """The ring's own place on each frame from the launch to the beat, as an At track counted from the beat."""
    return [[f - beat, k.v3(n[f][ring]), "Linear"] for f in range(beat - FLIGHT, beat + 1)]


def shots():
    n = measure(list(range(min(HITS.values()) - FLIGHT, max(HITS.values()) + 1)))
    rows = {}
    for hit, rings in FIRES.items():
        beat = HITS[hit]
        for ring in rings:
            side = ring[-1]
            path = launch_path(n, ring, beat)
            path[-1] = path[-1][:2]
            a, b = MOUTH["scale"]
            rows[f"{hit}Mouth{side}"] = {
                "Kind": "Mesh", "From": hit, "Part": [HOOP], "Look": LOOK, "Grey": LOOK, "Color": WHITE, "Turn": FACE,
                "Why": f"{hit}: the ring leaves the {'right' if side == 'R' else 'left'} speaker's mouth as it drives forward",
                "Tracks": {"At": path,
                           "Scale": [[-FLIGHT, {"Vector3": [a, 1, a]}, "Quart Out"], [-FLIGHT + MOUTH["life"], {"Vector3": [b, 1, b]}]],
                           "Glow": [[-FLIGHT, 1.5, "Quad Out"], [-FLIGHT + MOUTH["life"], 0]],
                           "Transparency": [[-FLIGHT, 0, "Quad In"], [-FLIGHT + MOUTH["life"], 1]]}}
            rows[f"{hit}Flash{side}"] = {
                "Kind": "Light", "From": hit, "Range": 6, "Color": WHITE,
                "Why": f"{hit}: the speaker's light as it fires",
                "Tracks": {"At": path, "Brightness": [[-FLIGHT, 3, "Quart Out"], [2, 0]]}}
    for name, ring, hit in (("Shot1", "RingR", "Shot1"), ("Shot2", "RingL", "Shot2"), ("Shot3R", "RingR", "Shot3"),
                            ("Shot3L", "RingL", "Shot3")):
        rows[name] = {"Kind": "Streak", "Body": ring, "From": hit, "Color": {"Color3": [225, 225, 225]}, "Tracks": {},
                      "Why": f"{name}: the builder's streak from the speaker to the target, until the pulse flies (AR26)"}
    return rows


def pulse():
    beam = {"FaceCamera": True, "TextureMode": "Stretch", "TextureLength": 1, "TextureSpeed": 0,
            "LightEmission": 1, "LightInfluence": 0, "Brightness": 2, "Segments": 1}
    a, b = PULSE["scale"]
    width, lag, see = PULSE["trail"]
    return {
        "Ring": {"Kind": "Mesh", "Part": [HOOP], "Look": LOOK, "Grey": LOOK, "Color": WHITE, "Turn": FACE,
                 "Why": "the ring of sound in flight, swelling as it comes: its frame faces the target square, a wavefront",
                 "Tracks": {"Scale": [[0, {"Vector3": [a, 1, a]}, "Quad Out"], [FLIGHT, {"Vector3": [b, 1, b]}]],
                            "Glow": [[0, PULSE["glow"]]], "Transparency": [[0, 0]]}},
        "Trail": {"Kind": "Beam", "Image": GREY, "Grey": GREY, "Color": WHITE, "Beam": beam, "Taper": 0.2,
                  "Trail": {"Back": 0, "Beyond": 0}, "Why": "a faint line back along its flight, so the travel reads",
                  "Tracks": {"Lag": [[0, lag]], "Width": [[0, width]], "Transparency": [[0, see]]}},
        "Light": {"Kind": "Light", "Range": 5, "Color": WHITE, "Why": "the pulse's light, carried with it",
                  "Tracks": {"Brightness": [[0, 2]]}},
    }


def burst(rolls=(0,)):
    a, b = BURST["from"], BURST["to"]
    rows = {}
    for i, roll in enumerate(rolls):
        rows[f"Ring{i + 1}" if len(rolls) > 1 else "Ring"] = {
            "Kind": "Mesh", "Part": [HOOP], "Look": LOOK, "Grey": LOOK, "Color": WHITE, "Turn": FACE,
            "Why": "the burst: the pulse's ring thrown wide and low before the Shade's belly, on the beat"
                   + (f", rolled {roll} degrees: the two cross" if roll else ""),
            "Tracks": {**({"Tilt": [[0, {"Vector3": [0, 0, roll]}]]} if roll else {}),
                       "Scale": [[0, {"Vector3": [a[0], 1, a[1]]}, "Quart Out"], [BURST["out"], {"Vector3": [b[0], 1, b[1]]}]],
                       "Glow": [[0, BURST["glow"], "Quad Out"], [BURST["gone"], 0]],
                       "Transparency": [[0, 0, "Linear"], [2, 0, "Quad In"], [BURST["gone"], 1]]}}
    rows["Light"] = {"Kind": "Light", "Range": 9 if len(rolls) == 1 else 11, "Color": WHITE,
                     "Why": "the burst's light: it rims the Shade from her side",
                     "Tracks": {"At": [[0, {"Vector3": [0, 0, 0.3]}]], "Brightness": [[0, 5 if len(rolls) == 1 else 7, "Quart Out"], [7, 0]]}}
    return rows


def landing(ahead, start):
    """Where the pulse lands, the Shade `ahead` studs before her: LAND up, STANDOFF before the torso's face, across
    where the line from `start` to the Shade's middle meets that face; and the burst's frame there (right, up, back),
    facing the Shade's front, as it faces her."""
    front = -ahead + 0.74 + STANDOFF
    hit = [start[0] * (front + ahead) / (start[2] + ahead), LAND, front]
    return hit, [1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]


def oval(frame, across, tall, roll=0.0, count=72):
    """An oval in the burst's face (half widths `across` and `tall`, rolled `roll` degrees), placed: as points."""
    hit, right, up, _ = frame
    r = math.radians(roll)
    out = []
    for i in range(count):
        u, v = across * math.cos(2 * math.pi * i / count), tall * math.sin(2 * math.pi * i / count)
        x, y = u * math.cos(r) - v * math.sin(r), u * math.sin(r) + v * math.cos(r)
        out.append(k.add(k.add(hit, k.mul(right, x)), k.mul(up, y)))
    return out


def rims(frame, roll=0.0, steps=6):
    """Every place the burst's hoop passes as it opens: its outer and inner rims at `steps` sizes from its first to
    its widest."""
    (a0, b0), (a1, b1) = BURST["from"], BURST["to"]
    pts = []
    for i in range(steps + 1):
        t = i / steps
        a, b = a0 + (a1 - a0) * t, b0 + (b1 - b0) * t
        pts += oval(frame, a, b, roll) + oval(frame, a * INNER, b * INNER, roll)
    return pts


def flight(start, end, steps=10):
    """The pulse's ring in flight: its rim at `steps` places from the speaker to where it lands, facing the Shade
    square (a wavefront coming at it), whatever its flight's pitch and yaw."""
    right, up = [1.0, 0.0, 0.0], [0.0, 1.0, 0.0]
    a, b = PULSE["scale"]
    pts = []
    for i in range(steps + 1):
        t = i / steps
        c, r = k.add(start, k.mul(k.sub(end, start), t)), a + (b - a) * t
        pts += [k.add(c, k.add(k.mul(right, r * math.cos(q)), k.mul(up, r * math.sin(q))))
                for q in (2 * math.pi * j / 24 for j in range(24))]
    return pts


def rk_cross(a, b):
    return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]


def guard(points, ahead, what, margin=0.1):
    """Rule 4: no point under the street, and against every target, landed on it as the flight lands it
    (combo_targets: the ordinary Shade under each mask, the elite, the Lamplighter), none within `margin` of a part
    or drawing over a face from any view."""
    bad = []
    if min(p[1] for p in points) < 0.15:
        bad.append(f"{what} goes down to {min(p[1] for p in points):.2f} up (the Shade {ahead} ahead)")
    return bad + ct.rule4(points, ahead, what, land=LAND, margin=margin)


def checks(ahead):
    """Each shot's flight and burst against the guard, and how much of the burst's widest rim shows from each heading."""
    n = measure([HITS[h] - FLIGHT for h in HITS] + list(HITS.values()))
    bad, shown = [], {}
    for hit, rings in FIRES.items():
        rolls = (BURST["cross"], -BURST["cross"]) if len(rings) > 1 else (0.0,)
        for ring in rings:
            start = n[HITS[hit] - FLIGHT][ring]
            frame = landing(ahead, start)
            near = [q for q in flight(start, frame[0], steps=30) if k.length(k.sub(q, frame[0])) <= ARRIVAL]
            bad += guard(near, ahead, f"{hit} {ring}'s pulse arriving")
            for roll in rolls:
                bad += guard(rims(frame, roll), ahead, f"{hit} {ring}'s burst (rolled {roll})")
            widest = oval(frame, *BURST["to"], rolls[0]) + oval(frame, BURST["to"][0] * INNER, BURST["to"][1] * INNER, rolls[0])
            boxes = w.shade_boxes(ahead)
            shown[f"{hit} {ring}"] = {h: sum(1 for p in widest if not w.covered(p, w.camera(ahead, h), boxes)) / len(widest)
                                       for h in HEADINGS}
    return bad, shown


def write_rows(out_dir):
    read_action()
    effects = [
        {"Schema": "rows/1", "Effect": "LyricShots",
         "Why": "Lyric's shots (LyricCombo), the grey block (AR26; research's feel line, 08:06): as each speaker drives "
                "forward into its beat the ring leaves its mouth with a light, on the ring's own path; the builder's "
                "streaks run to the target until the pulse flies. Written by tools/blender/lyric_combo_fx.py.",
         "Area": 1, "Grey": True, "Action": ACTION, "Rows": shots()},
        {"Schema": "rows/1", "Effect": "LyricPulse",
         "Why": "Lyric's pulse (AR26): the flight's own look, a ring of sound riding its head from the speaker to the "
                f"Shade over {FLIGHT} frames, landing on the beat. Written by tools/blender/lyric_combo_fx.py.",
         "Area": 1, "Grey": True, "Rows": pulse()},
        {"Schema": "rows/1", "Effect": "LyricBurst",
         "Why": "Lyric's burst (AR26): where a pulse lands, facing the Shade's front, its ring thrown wide and low "
                "before the Shade's belly, and a light. Written by tools/blender/lyric_combo_fx.py.",
         "Area": 1, "Grey": True, "Rows": burst()},
        {"Schema": "rows/1", "Effect": "LyricBurstBoth",
         "Why": "Lyric's third (AR26): both pulses land on the same frame, and their two rings open crossed. Played once, "
                "between where the two land. Written by tools/blender/lyric_combo_fx.py.",
         "Area": 1, "Grey": True, "Rows": burst((BURST["cross"], -BURST["cross"]))},
    ]
    problems = sum((k.check(e, USED) for e in effects), [])
    for ahead in (spacing(), CLOSE):
        problems += checks(ahead)[0]
    if problems:
        raise SystemExit("the rows don't pass their own check:\n  " + "\n  ".join(problems))
    out_dir.mkdir(parents=True, exist_ok=True)
    for e in effects:
        (out_dir / f"{e['Effect']}.rows.json").write_text(json.dumps(e, indent=1) + "\n", encoding="utf-8")
        print(f"Written to {out_dir}: {e['Effect']} ({len(e['Rows'])} rows)")
    for ahead in (spacing(), CLOSE):
        print(f"  the burst at its widest, the Shade {ahead} ahead: share of its rims that shows, by heading")
        for name, by in checks(ahead)[1].items():
            print(f"    {name}: " + "  ".join(f"{h} {v * 100:.0f}%" for h, v in by.items()))
    print(f"  no flight or burst goes under the street, enters a target or draws over its face from {len(ct.VIEWS)} views, "
          f"landed as the flight lands it: {', '.join(ct.targets())}")


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
            speeds = [k.length(k.sub(p[r], last[r])) * 60 if last else 0.0 for r in SPEAKERS]
            last = p
            mark = next((h for h, v in HITS.items() if v == f), "")
            print(f"{f:3d} {mark:5s} " + " ".join(f"{r}=({v[0]:+.2f},{v[1]:+.2f},{v[2]:+.2f})" for r, v in p.items())
                  + "  " + " ".join(f"{s:5.1f}" for s in speeds) + " st/s")
        return
    print(__doc__)
    sys.exit(2)


if __name__ == "__main__":
    main()
