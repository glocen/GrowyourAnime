"""Watt's Ground Wire, its look as rows (AR11, "Ground Wire's look: the parts and their techniques"; AR8, "The method";
the grey block of /ga-action step 3).

py tools/blender/watt_ground_wire_fx.py measure
py tools/blender/watt_ground_wire_fx.py screen
py tools/blender/watt_ground_wire_fx.py rows <out_dir>

Plain Python, no Blender. Its numbers come from the delivered clip (build/handoff/Watt/clips/Watt_GroundWire.json, the
Transforms the game plays) on the recipe's one joint, the spear on the Torso, and from the action's own row (read only:
src/shared/Definitions/Actions.luau, the Plant's Round, and Config.Combat's rung 7 hold).
- measure: the spear's butt, discs and blade in his root's frame through the clip.
- screen: from cameras round the fight, how much of the plant (a ring a stud round the butt's foot, and the shaft) the
  target Shade covers, at rest, 3.5 to 5.5 studs ahead of him (the content check's note 2).
- rows: three files, schema rows/1 (docs/engineering-plan.md, "The rows contract"), in grey:
  WattGroundWire.rows.json, the action's own; WattGroundWireStop.rows.json, on each stopped body; and
  WattGroundWireShield.rows.json, on him while his shield lasts. The last two are played by the builder's code.

The hero is the ring: a thin wall of light along the street, out from the butt's foot to the stop's reach, snapping
out and braking, its centre drifting to his root so its edge at full size is the stop's. Before it, a short light runs
down the shaft with the drive; on the Plant a light and a low spray of sparks at the foot, glints let go along the
ring's rim, and the discs and the hair flare and hum through the hold. Each stopped Shade gets a small ring at its feet
that closes in on it, and his shield is faint light standing up from the street round him.
"""
import json
import math
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kirra_scarf_step_fx as k  # noqa: E402  (the CFrame sums, the Track reader, the rows file check, the Shade's boxes)

ROOT = Path(__file__).resolve().parents[2]
RECIPE = ROOT / "build" / "handoff" / "Watt" / "Watt.recipe.json"
CLIP = ROOT / "build" / "handoff" / "Watt" / "clips" / "Watt_GroundWire.json"
ACTIONS = ROOT / "src" / "shared" / "Definitions" / "Actions.luau"  # read only
COMBAT = ROOT / "src" / "shared" / "Config" / "Combat.luau"  # read only
ACTION = "WattGroundWire"
PLANT, RELEASE = 25, 124  # the clip's markers, checked against it
LIFT_TOP = 16  # both hands up: the drive starts
OUT_BY = 136  # the spear out of the street
ROOT_HEIGHT = 3.0  # R6: the HumanoidRootPart's centre over the floor
SPEAR = "Watt_Spear"
HAIR = "Watt_Head"
GREY_LOOK = "fx_rise_Grey"
WHITE = {"Color3": [255, 255, 255]}
USED = ("fx_beam", "fx_spark", GREY_LOOK, "FxColumn", "FxShell")  # checked against Config.FxKit
UNIT = 2.0  # FxColumn's and FxShell's unit size across (fx_kit.json): a Scale of r is r studs round
HUM = 15  # frames between a hum's high and low: twice a second
CAP = 600  # frames the stop's and the shield's rows hold to; the builder's code ends them with the stun or the shield

# The ring (DESIGN seeds, tuned live): out over SNAP frames, Quart Out, from START studs round; a wall HEIGHT tall at the
# foot and EDGE_HEIGHT at the edge; whole until SNAP, gone by GONE.
SNAP, GONE = 10, 28
START, HEIGHT, EDGE_HEIGHT = 0.3, 0.7, 0.24
CHARGE = 1.2  # studs: the light that runs down the shaft
STOP_ROUND, STOP_FROM, STOP_CLOSE = 1.7, 2.8, 4  # the stop's ring: studs round, from, frames to close
SHIELD = {"across": 4.0, "top": 5.8, "centre": 1.8}  # studs: its widest, its top over the street, its centre's height


def read_action():
    """The Plant's Round and Stun, and the action's beats, from its row in Definitions/Actions; rung 7's hold in frames
    from Config.Combat. Never copied: a change there is read here on the next run."""
    text = ACTIONS.read_text(encoding="utf-8")
    start = text.index(f'Id = "{ACTION}"')
    block = text[start:text.index("Id = ", start + 10)]
    plant = re.search(r"Plant = \{[^\n]*\}", block).group(0)
    found = {key: float(re.search(rf"\b{key} = ([\d.]+)", plant).group(1)) for key in ("Round", "Stun", "Rung")}
    beats = {n: round(float(v) * 60) for n, v in re.findall(r"(\w+) = ([\d.]+)", re.search(r"Beats = \{([^}]*)\}", block).group(1))}
    if beats != {"Plant": PLANT, "Release": RELEASE}:
        raise SystemExit(f"the action's beats moved: {beats}")
    rung = re.search(rf"\{{ From = {int(found['Rung'])}, Hold = ([\d.]+)", COMBAT.read_text(encoding="utf-8"))
    found["Hold"] = round(float(rung.group(1)) * 60)
    return found


def measure(frames=None):
    """The spear's points in his root's frame, frame by frame: the Torso on R6's RootJoint, the spear's joint on the
    Torso at its pivot with the model's axes at rest (docs/engineering-plan.md, "The recipe contract")."""
    recipe = json.loads(RECIPE.read_text(encoding="utf-8"))
    clip = json.loads(CLIP.read_text(encoding="utf-8"))
    marks = {m["Name"]: round(m["T"] * clip["Fps"]) for m in clip["Markers"]}
    if marks != {"Plant": PLANT, "Release": RELEASE}:
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
        out[f] = {n: k.compose(joint, k.moved(k.sub(points[n], spear["pivot"])))[1] for n in ("Butt", "SpearHead", "Blade")}
    shaft = k.sub(points["SpearHead"], points["Butt"])  # in the spear's own axes (the model's at rest)
    return {"at": out, "shaft": k.unit(shaft), "discs_up": k.length(shaft)}


def plant_foot(n):
    """The butt in the street through the hold, in the effect's foot's frame (his root set down, facing as he does)."""
    butts = [n["at"][f]["Butt"] for f in range(PLANT, OUT_BY + 1)]
    if max(abs(b[1] + ROOT_HEIGHT) for b in butts) > 0.02 or max(k.length(k.sub(b, butts[0])) for b in butts) > 0.02:
        raise SystemExit("the butt doesn't stand still in the street through the hold")
    return [round(butts[0][0], 3), 0.0, round(butts[0][2], 3)]


def hum(t0, t1, high, low, ease="Sine InOut"):
    """Keys from t0 to t1 between high and low every HUM frames, starting and ending high."""
    keys, t, up = [], t0, True
    while t < t1:
        keys.append([t, high if up else low, ease])
        t, up = t + HUM, not up
    keys.append([t1, high, ease])
    return keys


def glow_row(part, lift, flare, hot, low, release, why):
    return {"Kind": "Glow", "Part": [part], "Why": why, "Tracks": {"Glow": (
        [[0, 0, "Sine InOut"], [LIFT_TOP, lift, "Linear"], [PLANT, lift, "Linear"], [PLANT + 1, flare, "Quad Out"]]
        + hum(PLANT + 9, release, hot, low)[:-1] + [[release, hot, "Quad Out"], [release + 16, 0]])}}


def ground_wire(n, act):
    foot = plant_foot(n)
    release = RELEASE + int(act["Hold"])  # on the free clock from the Plant, so the hold's frames come first
    r = act["Round"]
    rows = {
        "Discs": glow_row(SPEAR, 1.4, 3.2, 2.5, 1.9, release,
                          "the three discs gather on the lift, flare on the Plant, hum through the hold, and go out as "
                          "he pulls it free (the recipe's hot 2.5)"),
        "Hair": glow_row(HAIR, 0.5, 3.0, 2.2, 1.7, release, "the hair's pale ends, with the discs (the recipe's hot 3)"),
        "Charge": {
            "Kind": "Beam", "Body": "Butt", "Image": "fx_beam", "Grey": "fx_beam", "Color": WHITE,
            "Why": "a short light runs down the shaft with the drive, from the discs into the street: the drive's read",
            "Beam": {"FaceCamera": True, "TextureMode": "Stretch", "TextureLength": 1, "TextureSpeed": 0,
                     "LightEmission": 1, "LightInfluence": 0, "Brightness": 2, "Segments": 1},
            "Tracks": {
                "Tilt": [[LIFT_TOP, k.v3(k.tilt_for(n["shaft"]))]],
                "Foot": [[LIFT_TOP, round(n["discs_up"] - CHARGE, 3), "Quad In"], [PLANT, 0, "Linear"], [PLANT + 2, 0]],
                "Top": [[LIFT_TOP, round(n["discs_up"], 3), "Quad In"], [PLANT, CHARGE, "Quad In"], [PLANT + 2, 0]],
                "Width": [[LIFT_TOP, 0.25, "Quad In"], [PLANT, 0.5, "Linear"], [PLANT + 2, 0.3]],
                "Transparency": [[LIFT_TOP, 0.3, "Quad In"], [PLANT, 0, "Linear"], [PLANT + 2, 0.6]],
            },
        },
        "PlantAt": {"Kind": "Point", "From": "Plant", "Why": "the butt's foot in the street, measured from the clip",
                    "Tracks": {"At": [[0, k.v3(foot)]]}},
        "PlantLight": {"Kind": "Light", "On": "PlantAt", "From": "Plant", "Range": 16, "Color": WHITE,
                       "Tracks": {"At": [[0, k.v3([0, 1.0, 0])]],
                                  "Brightness": [[0, 6, "Quart Out"], [6, 2.5, "Sine InOut"], [24, 0]]}},
        "Sparks": {
            "Kind": "Emitter", "On": "PlantAt", "From": "Plant", "Image": "fx_spark", "Emit": [[0, 16]],
            "Why": "a low spray all round along the street, never up (the content check's note 2): from Front, X tips "
                   "it up and Y turns it round; if the replay shows a wall, swap them",
            "Emitter": {"Lifetime": [0.15, 0.3], "Speed": [14, 24], "SpreadAngle": [6, 180], "EmissionDirection": "Front",
                        "Drag": 9, "Acceleration": k.v3([0, -10, 0]), "Size": [[0, 0.5], [1, 0]],
                        "Transparency": [[0, 0], [0.7, 0], [1, 1]], "Rotation": [0, 360], "LightEmission": 1,
                        "LightInfluence": 0},
            "Tracks": {"At": [[0, k.v3([0, 0.15, 0])]]},
        },
        "Ring": {
            "Kind": "Mesh", "Part": ["FxColumn"], "Look": GREY_LOOK, "Grey": GREY_LOOK, "Color": WHITE, "From": "Plant",
            "Why": f"the hero: a low wall of light out from the butt's foot to the stop's reach (Round {r:g}), snapping "
                   "out and braking, its centre drifting to his root so its edge at full size is the stop's",
            "Tracks": {
                "At": [[0, k.v3(foot), "Quart Out"], [SNAP, k.v3([0, 0, 0])]],
                "Scale": [[0, k.v3([START, HEIGHT / UNIT, START]), "Quart Out"], [SNAP, k.v3([r, EDGE_HEIGHT / UNIT, r])]],
                "Transparency": [[0, 0, "Linear"], [SNAP, 0, "Quad In"], [GONE, 1]],
                "Glow": [[0, 2.5, "Quad Out"], [SNAP, 1.6, "Linear"], [GONE, 0.6]],
            },
        },
        "Front": {
            "Kind": "Emitter", "On": "Ring", "From": "Plant", "Image": "fx_spark",
            "Why": "glints let go along the ring's rim as it travels: layer 3 at most",
            "Emitter": {"Shape": "Disc", "ShapeStyle": "Surface", "EmissionDirection": "Top", "Lifetime": [0.12, 0.25],
                        "Speed": [0.5, 2], "Drag": 4, "Size": [[0, 0.35], [1, 0]], "Transparency": [[0, 0], [1, 1]],
                        "Rotation": [0, 360], "LightEmission": 1, "LightInfluence": 0},
            "Tracks": {"Radius": [[0, 1]], "Rate": [[0, 420, "Linear"], [SNAP - 2, 0]]},
        },
    }
    return {"Schema": "rows/1", "Effect": ACTION,
            "Why": "Watt's Ground Wire, the grey block (AR11, \"Ground Wire's look\"). Free on the Plant: the ring runs "
                   f"through rung 7's hold of {int(act['Hold'])} frames while the bodies are held, so the glows' release is "
                   "written that much late to stay on the clip. Written by tools/blender/watt_ground_wire_fx.py.",
            "Area": 1, "Grey": True, "Action": ACTION, "Free": "Plant", "Rows": rows}


def stop():
    trans = [[0, 0, "Linear"], [STOP_CLOSE, 0.15, "Sine InOut"]] + hum(STOP_CLOSE + HUM, CAP, 0.15, 0.45)
    rows = {"Lock": {
        "Kind": "Mesh", "Part": ["FxColumn"], "Body": "HumanoidRootPart", "Ground": True, "Look": GREY_LOOK,
        "Grey": GREY_LOOK, "Color": WHITE,
        "Why": "a small ring of the hero's light at the stopped body's feet, closing in on it, humming with the discs",
        "Tracks": {
            "Scale": [[0, k.v3([STOP_FROM, 0.2, STOP_FROM]), "Quart Out"], [STOP_CLOSE, k.v3([STOP_ROUND, 0.1, STOP_ROUND])]],
            "Transparency": trans,
            "Glow": [[0, 2.2, "Quad Out"], [6, 1.4]],
        },
    }}
    return {"Schema": "rows/1", "Effect": "WattGroundWireStop",
            "Why": "Ground Wire's stop, on each body it holds (AR11): played by the builder's stop for as long as that "
                   "body's stun lasts and ended with it, at once: the lock lets go. No arcs, sparks or flinch on the body. "
                   f"Its rows hold to frame {CAP}. Written by tools/blender/watt_ground_wire_fx.py.",
            "Area": 1, "Grey": True, "Rows": rows}


def shield():
    s = SHIELD
    size = [s["across"] / 2, s["top"] - s["centre"], s["across"] / 2]  # the unit shell is 1 stud round
    rim = s["across"] * math.sqrt(1 - (s["centre"] / size[1]) ** 2)
    rows = {"Shell": {
        "Kind": "Mesh", "Part": ["FxShell"], "Body": "HumanoidRootPart", "Ground": True, "Look": GREY_LOOK,
        "Grey": GREY_LOOK, "Color": WHITE,
        "Why": "faint light standing up from the street round him, bright at its foot (the rise ramp), its lower part "
               f"under the street, so only a rim {rim:.1f} across meets it",
        "Tracks": {
            "At": [[0, k.v3([0, s["centre"], 0])]],
            "Scale": [[0, k.v3(k.mul(size, 0.8)), "Quart Out"], [6, k.v3(size)]],
            "Transparency": [[0, 0.4, "Quad Out"], [10, 0.86, "Sine InOut"]] + hum(10 + HUM, CAP, 0.86, 0.92),
            "Glow": [[0, 1.8, "Quad Out"], [10, 0.8]],
        },
    }}
    return {"Schema": "rows/1", "Effect": "WattGroundWireShield",
            "Why": "Ground Wire's shield on Watt (AR11): played from his ShieldUntil and ended with the shield. Its rows "
                   f"hold to frame {CAP}. Written by tools/blender/watt_ground_wire_fx.py.",
            "Area": 1, "Grey": True, "Rows": rows}


def write_rows(out):
    act = read_action()
    n = measure(range(PLANT, OUT_BY + 1))
    effects = (ground_wire(n, act), stop(), shield())
    problems = [f"{e['Effect']}: {p}" for e in effects for p in k.check(e, USED)]
    if problems:
        raise SystemExit("the rows don't pass their own check:\n  " + "\n  ".join(problems))
    out.mkdir(parents=True, exist_ok=True)
    for e in effects:
        (out / f"{e['Effect']}.rows.json").write_text(json.dumps(e, indent=1) + "\n", encoding="utf-8")
    ring = effects[0]["Rows"]["Ring"]["Tracks"]["Scale"]
    radii = [round(k.value(ring, t)[0], 2) for t in range(0, SNAP + 1)]
    print(f"Written to {out}: " + ", ".join(f"{e['Effect']} ({len(e['Rows'])} rows)" for e in effects))
    print(f"  the butt's foot {plant_foot(n)}; the stop's Round {act['Round']:g}, rung {int(act['Rung'])}'s hold "
          f"{int(act['Hold'])} frames; the discs {n['discs_up']:.2f} studs up the shaft")
    print("  the ring's radius by frame after the Plant: " + " ".join(str(x) for x in radii))


def screen():
    n = measure([PLANT])
    foot = plant_foot(measure(range(PLANT, OUT_BY + 1)))
    blade = k.add(n["at"][PLANT]["Blade"], [0, ROOT_HEIGHT, 0])
    recipe = json.loads(k.SHADE_RECIPE.read_text(encoding="utf-8"))
    parts = [p for p in recipe["pieces"] if "centre" in p] + [recipe["masks"][k.MASK]]

    def covered(eye, p, boxes):
        to = k.sub(p, eye)
        far = k.length(to)
        way = k.mul(to, 1 / far)
        return any(e and e[0] < far for e in (k.entering(eye, way, b) for b in boxes))

    print("The target Shade at rest, facing him, `ahead` studs out. By heading round its chest (0 behind him, 215 the "
          "replay's): Y if it covers the butt's foot / points of a 1-stud ring round it covered (of 16) / points of "
          "the shaft covered (of 20).")
    for ahead in (3.5, 4.5, 5.5):
        boxes = [([-p["centre"][0], p["centre"][1], -p["centre"][2] - ahead], [s / 2 for s in p["size"]]) for p in parts]
        chest = [0.0, k.CHEST, -ahead]
        cells = []
        for h in range(150, 285, 10):
            a = math.radians(h)
            eye = k.add(chest, [math.sin(a) * k.CAMERA_OUT, k.CAMERA_UP, math.cos(a) * k.CAMERA_OUT])
            ring = [k.add(foot, [math.cos(2 * math.pi * i / 16), 0.05, math.sin(2 * math.pi * i / 16)]) for i in range(16)]
            shaft = [k.add(foot, k.mul(k.sub(blade, foot), (i + 0.5) / 20)) for i in range(20)]
            cells.append(f"{h}:{'Y' if covered(eye, k.add(foot, [0, 0.05, 0]), boxes) else '-'}/"
                         f"{sum(covered(eye, p, boxes) for p in ring)}/{sum(covered(eye, p, boxes) for p in shaft)}")
        print(f"  {ahead} ahead: " + "  ".join(cells))


def main():
    if sys.argv[1:2] == ["measure"]:
        n = measure()
        for f, p in n["at"].items():
            if f % 5 == 0 or f in (PLANT - 1, PLANT, RELEASE):
                print(f"{f:3d} " + " ".join(f"{name}=({v[0]:+.2f},{v[1] + ROOT_HEIGHT:+.2f},{v[2]:+.2f})"
                                            for name, v in p.items()))
        print("(his root's frame, y from the floor: x right, z back)")
        return
    if sys.argv[1:2] == ["screen"]:
        screen()
        return
    if len(sys.argv) < 3 or sys.argv[1] != "rows":
        print(__doc__)
        sys.exit(2)
    write_rows(Path(sys.argv[2]))


if __name__ == "__main__":
    main()
