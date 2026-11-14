"""Kirra's Scarf Step, its look as rows (AR10, delivery 4; AR8, "The method"; the grey block of /ga-action step 3).

py tools/blender/kirra_scarf_step_fx.py rows <out_dir>
blender.exe -b --factory-startup --python tools/blender/kirra_scarf_step_fx.py -- <out_dir> preview

- rows (plain Python, no Blender): KirraScarfStep.rows.json, take A, the line on the scarf through the Shade, and
  KirraScarfStepFlank.rows.json, take B, the line turned past the Shade's flank (research's technique check: both in
  the first block, judged at 64 px from the player's camera). Schema rows/1 (docs/engineering-plan.md, "The rows
  contract"), in grey. Its numbers come from the delivered clip, build/handoff/Kirra/clips/Kirra_ScarfStep.json, the
  Transforms the game plays, chained on the recipe's joints: the scarf's knot and tip in her root's frame, frame by frame.
  The Shade's chest is the clip's, in the effect's foot's frame as the game sets it (Effects.Play: her root at the
  action's start, set down to the floor, facing as she does; she faces the Shade).
- preview (in Blender, on the clip's rig): the line drawn in grey from the player's camera, A then B, alone and then with
  the crescent (motion before layers), full size and at 64 px: scarf_step_line.png and scarf_step_crescent.png. The
  particles, the light, a Beam's fade and the self-lit look aren't drawn: the engine's take judges those. Needs
  kirra_model.py's output, as kirra_clips.py does, and about 1 GB.

The hero is the line: the scarf, which the clip holds straight from her knot back through the Shade from Land to 40,
and a Beam of light laid on it, riding her root so it stays on the scarf wherever the game lands her. It swells on the
Cut, narrows toward where she was (a stroke drawn toward her), and burns off from its far end into her knot, slow then
fast, gone as the cloth lets go from its tip at 44: the light first, the cloth after. Then the crescent on the way out,
swept on the Shade at the Cut, never as bright as the line's swell; sparks thrown on along her line; a light on the cut;
a puff where she was and dust as she slides.
"""
import json
import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RECIPE = ROOT / "build" / "handoff" / "Kirra" / "Kirra.recipe.json"
CLIP = ROOT / "build" / "handoff" / "Kirra" / "clips" / "Kirra_ScarfStep.json"
FXKIT = ROOT / "src" / "shared" / "Config" / "FxKit.luau"  # read only: the kit's names, for the file's own check
ACTION = "KirraScarfStep"
BLINK, LAND, CUT = 13, 16, 18  # the clip's markers (AR10, section 4), checked against the clip
HOLD_TO = 40  # the line holds straight to here
BURN = (38, 46)  # its far end runs up it into her knot, slow then fast; the cloth lets go from its tip at 44
KEYS = (16, 20, 24, 32, 40, 44, 46)  # the frames the line's place and aim are keyed on, from the clip
ROOT_HEIGHT = 3.0  # R6: the HumanoidRootPart's centre over the floor, and the Torso at it at rest
GONE, PAST = 5.0, 3.8  # the clip's Shade ahead of her start, and how far past it she lands (kirra_clips, kirra_sheet)
CHEST = 3.0  # the Shade's chest over the floor, where the clip aims her line (kirra_clips.scarf_step's at_shade)
CAMERA_SIDE = 1.0  # the player's camera stands to her right of the line (+x of the effect's foot): the clip's crossing
# runs 35 degrees right of the camera's line (AR10, section 1's tier 2). A crossing mirrored in the game flips it.
FLANK = 1.5  # take B: studs off the Shade's middle at which the line passes it, on the camera's side (the grey
# Shade's coat is 2.2 across at its chest: 0.4 clear)
TAPER = 0.45  # the line's width where she was, as a share of its width at her knot
WIDTH = ((0, 0.3, "Quad Out"), (2, 0.75, "Quad Out"), (10, 0.34, "Sine InOut"), (22, 0.3, "Linear"), (30, 0.18))  # from Land
ROLL = 35.0  # the crescent rolled about her line, its face tipped up toward the camera's side
GREY_LOOK = "fx_across_Grey"
WHITE = {"Color3": [255, 255, 255]}
IMAGES = ("fx_beam", "fx_glow", "fx_spark", GREY_LOOK)  # checked against Config.FxKit before anything is written
MESHES = ("FxCrescent",)
# The fields a rows file may hold, as Config.EffectRows has them, and the kinds and eases the player knows.
TOP = {"Schema", "Effect", "Why", "Area", "Grey", "Action", "Free", "Rows"}
FIELDS = {"Kind", "On", "Part", "Look", "Grey", "Image", "Color", "Range", "Emitter", "Emit", "Tracks", "Bands", "From",
          "Body", "Ground", "Hold", "Turn", "Beam", "Trail", "Low", "High", "Like", "FootFade", "Taper", "Cue", "Relight",
          "Why"}
KINDS = {"Mesh", "Card", "Emitter", "Light", "Glow", "Point", "Beam", "Streak", "Sound", "Relight"}
STYLES = {"Quad", "Cubic", "Quart", "Quint", "Sine", "Exponential", "Circular", "Back"}


# --- small 3D sums, Roblox's axes: x right, y up, z back --------------------------------------------------------------

def add(a, b):
    return [a[i] + b[i] for i in range(3)]


def sub(a, b):
    return [a[i] - b[i] for i in range(3)]


def mul(a, s):
    return [a[i] * s for i in range(3)]


def dot(a, b):
    return sum(a[i] * b[i] for i in range(3))


def length(a):
    return math.sqrt(dot(a, a))


def unit(a):
    return mul(a, 1 / length(a))


def rot(r, v):
    return [dot(r[i], v) for i in range(3)]


def compose(a, b):
    """CFrame a * b, each (rows of the rotation, position)."""
    (ra, pa), (rb, pb) = a, b
    r = [[sum(ra[i][k] * rb[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
    return r, add(pa, rot(ra, pb))


def inverse(a):
    r, p = a
    t = [[r[j][i] for j in range(3)] for i in range(3)]
    return t, mul(rot(t, p), -1)


def cframe(n):
    """A clip's 12 numbers: x, y, z, then the rotation row by row, as CFrame.new takes them."""
    return [n[3:6], n[6:9], n[9:12]], list(n[0:3])


def moved(p):
    return [[1, 0, 0], [0, 1, 0], [0, 0, 1]], list(p)


def turned_about_up(deg):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return [[c, 0, s], [0, 1, 0], [-s, 0, c]]  # CFrame.Angles(0, deg, 0)


R6_ROOT = [[-1, 0, 0], [0, 0, 1], [0, 1, 0]], [0, 0, 0]  # R6's RootJoint C0 and C1


# --- Track.luau's keys, as the game reads them -----------------------------------------------------------------------

POWERS = {"Quad": 2, "Cubic": 3, "Quart": 4, "Quint": 5}


def eased(style, u):
    if style in POWERS:
        return u ** POWERS[style]
    if style == "Sine":
        return 1 - math.cos(u * math.pi / 2)
    if style == "Exponential":
        return 0.0 if u <= 0 else 2 ** (10 * (u - 1))
    if style == "Circular":
        return 1 - math.sqrt(max(0.0, 1 - u * u))
    if style == "Back":
        return u * u * (2.70158 * u - 1.70158)
    raise ValueError(style)


def ease(name, u):
    x = min(1.0, max(0.0, u))
    if not name or name == "Linear":
        return x
    style, way = name.split()
    if way == "In":
        return eased(style, x)
    if way == "Out":
        return 1 - eased(style, 1 - x)
    return eased(style, 2 * x) / 2 if x < 0.5 else 1 - eased(style, 2 - 2 * x) / 2


def plain(v):
    return list(v["Vector3"]) if isinstance(v, dict) else v


def value(keys, t):
    """Track.Value: the track's value at frame t after its beat; None before its first key."""
    if not keys or t < keys[0][0]:
        return None
    for a, b in zip(keys, keys[1:]):
        if t <= b[0]:
            span = b[0] - a[0]
            u = ease(a[2] if len(a) > 2 else None, (t - a[0]) / span) if span > 0 else 1.0
            va, vb = plain(a[1]), plain(b[1])
            if isinstance(va, list):
                return [x + (y - x) * u for x, y in zip(va, vb)]
            return va + (vb - va) * u
    return plain(keys[-1][1])


# --- the clip's numbers ------------------------------------------------------------------------------------------------

def v3(p):
    return {"Vector3": [round(c, 3) for c in p]}


def tilt_for(d):
    """Tilt (degrees: X, 0, Z) that turns a row's up onto the unit d: CFrame.Angles(x, 0, z) * (0, 1, 0) = d."""
    z = math.degrees(math.asin(max(-1.0, min(1.0, -d[0]))))
    x = math.degrees(math.atan2(d[2], d[1]))
    return [x, 0.0, z]


def up_of(tilt):
    """A row's up after its Tilt: CFrame.Angles(x, y, z) * (0, 1, 0), y taken as 0."""
    x, z = math.radians(tilt[0]), math.radians(tilt[2])
    v = [-math.sin(z), math.cos(z), 0.0]  # about Z first
    return [v[0], v[1] * math.cos(x) - v[2] * math.sin(x), v[1] * math.sin(x) + v[2] * math.cos(x)]  # then about X


def measure():
    """The scarf's knot and tip in her root's frame on each of KEYS, from the delivered clip on the recipe's joints:
    the Torso on R6's RootJoint, the first segment's joint on the Torso at the knot, each next on the one before, a
    joint's frame its pivot with the model's axes at rest (docs/engineering-plan.md, "The recipe contract")."""
    recipe = json.loads(RECIPE.read_text(encoding="utf-8"))
    clip = json.loads(CLIP.read_text(encoding="utf-8"))
    marks = {m["Name"]: round(m["T"] * clip["Fps"]) for m in clip["Markers"]}
    if marks != {"Blink": BLINK, "Land": LAND, "Cut": CUT}:
        raise SystemExit(f"the clip's markers moved: {marks}")
    points = {p["name"]: p["at"] for p in recipe["points"]}
    pieces = {p["name"]: p for p in recipe["pieces"]}
    chain = [f"Kirra_Scarf{k + 1}" for k in range(8)]
    for k, name in enumerate(chain):
        if pieces[name]["on"] != ("Torso" if k == 0 else chain[k - 1]):
            raise SystemExit(f"{name} isn't on the segment before it")
    torso_rest = [0.0, ROOT_HEIGHT, 0.0]
    knot_at = sub(points["Knot"], torso_rest)
    line = {}
    for f in KEYS:
        poses = clip["Frames"][f]["Poses"]
        torso = compose(compose(R6_ROOT, cframe(poses["Torso"])), inverse(R6_ROOT))  # in her root's frame
        joint = compose(compose(torso, moved(sub(pieces[chain[0]]["pivot"], torso_rest))), cframe(poses[chain[0]]))
        for before, name in zip(chain, chain[1:]):
            joint = compose(compose(joint, moved(sub(pieces[name]["pivot"], pieces[before]["pivot"]))), cframe(poses[name]))
        knot = compose(torso, moved(knot_at))[1]
        tip = compose(joint, moved(sub(points["ScarfTip"], pieces[chain[-1]]["pivot"])))[1]
        line[f] = {"knot": knot, "tip": tip}
    return {"line": line, "shade": [0.0, CHEST, -GONE]}


def landed(p):
    """A point in her root's frame at the landing, in the effect's foot's frame: as the clip lands her, GONE + PAST
    along her line, turned to face back along it (the game moves her; the rows don't depend on how)."""
    r = turned_about_up(180.0)
    return add(rot(r, p), [0.0, ROOT_HEIGHT, -(GONE + PAST)])


# --- the rows -----------------------------------------------------------------------------------------------------------

def line_row(n, turn_deg):
    """The line: one Beam on her root, from her knot along the scarf; turned `turn_deg` about up at the knot (take B)."""
    at, tilt, lengths = [], [], []
    turn = turned_about_up(turn_deg)
    for f in KEYS:
        knot, tip = n["line"][f]["knot"], n["line"][f]["tip"]
        d = rot(turn, sub(tip, knot))
        lengths.append(length(d))
        at.append([f - LAND, v3(knot), "Sine InOut"])
        if f <= HOLD_TO:  # the aim holds from 40: the light stays straight as the cloth lets go off it
            aim = tilt_for(unit(d))
            if length(sub(up_of(aim), unit(d))) > 1e-6:
                raise SystemExit(f"the tilt at {f} doesn't turn up onto the scarf")
            tilt.append([f - LAND, v3(aim), "Sine InOut"])
    at[-1], tilt[-1] = at[-1][:2], tilt[-1][:2]
    if all(length(sub(k[1]["Vector3"], tilt[0][1]["Vector3"])) < 0.05 for k in tilt):  # the clip holds the scarf rigid
        tilt = [tilt[0][:2]]
    top = round(min(lengths[i] for i, f in enumerate(KEYS) if f <= HOLD_TO), 2)
    return {
        "Kind": "Beam", "Body": "HumanoidRootPart", "From": "Land", "Image": "fx_beam", "Grey": "fx_beam", "Color": WHITE,
        "Why": "The hero: the light on the scarf, from her knot back through the Shade toward where she was. It rides her "
               "root, so it stays on the scarf wherever the game lands her: At and Tilt are the scarf's knot and aim in "
               "her root's frame, from the clip. It swells on the Cut, narrows toward where she was, and burns off from "
               "its far end into her knot from 38 to 46, slow then fast. The cloth lets go from its tip at 44.",
        "Beam": {"FaceCamera": True, "TextureMode": "Stretch", "TextureLength": 1, "TextureSpeed": 0, "LightEmission": 1,
                 "LightInfluence": 0, "Brightness": 2, "Segments": 10},
        "Taper": TAPER,
        "Tracks": {
            "At": at,
            "Tilt": tilt,
            "Foot": [[0, 0]],
            "Top": [[0, top, "Linear"], [BURN[0] - LAND, top, "Quad In"], [BURN[1] - LAND, 0]],
            "Width": [list(k) for k in WIDTH],
            "Transparency": [[0, 0.05, "Linear"], [BURN[1] - LAND, 0.05], [BURN[1] - LAND, 1]],
        },
    }, lengths


def effect(n, name, why, turn_deg):
    line, lengths = line_row(n, turn_deg)
    rows = {
        "Line": line,
        "Puff": {
            "Kind": "Emitter", "From": "Blink", "Ground": True, "Image": "fx_glow",
            "Why": "Where she was, at her feet as she blinks out: a small puff kicked on along her line, kept quiet.",
            "Emit": [[0, 6]],
            "Emitter": {"Lifetime": [0.25, 0.4], "Speed": [3, 6], "SpreadAngle": [25, 25], "EmissionDirection": "Front",
                        "Drag": 6, "Acceleration": v3((0, 1.5, 0)), "Size": [[0, 1.2], [1, 2.6]],
                        "Transparency": [[0, 0.45], [1, 1]], "Rotation": [0, 360], "RotSpeed": [-40, 40],
                        "LightEmission": 0.3, "LightInfluence": 0.6},
            "Tracks": {},
        },
        "Slide": {
            "Kind": "Emitter", "From": "Land", "Body": "HumanoidRootPart", "Ground": True, "Image": "fx_glow",
            "Why": "Low dust at her feet as she brakes on the landing, sprayed on along her slide.",
            "Emitter": {"Lifetime": [0.3, 0.5], "Speed": [2, 5], "SpreadAngle": [30, 30], "EmissionDirection": "Front",
                        "Drag": 5, "Acceleration": v3((0, 0.8, 0)), "Size": [[0, 0.7], [1, 1.6]],
                        "Transparency": [[0, 0.55], [1, 1]], "Rotation": [0, 360], "RotSpeed": [-30, 30],
                        "LightEmission": 0, "LightInfluence": 0.8},
            "Tracks": {"Rate": [[0, 50, "Quad Out"], [14, 0]]},
        },
        "CutAt": {
            "Kind": "Point", "From": "Cut",
            "Why": "The Shade's chest, the clip's 5 studs ahead of where she started. It should ride the target once the "
                   "rows can (research's view, Faber's code): auto-combat doesn't hold 5 studs.",
            "Tracks": {"At": [[0, v3(n["shade"])]]},
        },
        "Crescent": {
            "Kind": "Mesh", "On": "CutAt", "From": "Cut", "Part": ["FxCrescent"], "Look": GREY_LOOK, "Grey": GREY_LOOK,
            "Color": WHITE, "Turn": v3((0, 0, -ROLL * CAMERA_SIDE)),
            "Why": "The crescent on the way out: laid along her line, head toward where she lands, rolled open to the "
                   "player's camera, swept head first as it grows. Its Glow peaks under the line's swell.",
            "Tracks": {"Scale": [[0, v3((1.7, 1, 1.7)), "Quart Out"], [8, v3((2.3, 1, 2.3))]],
                       "Spin": [[0, 25, "Quart Out"], [8, 0]],
                       "Glow": [[0, 1.2, "Quad Out"], [12, 0]],
                       "Transparency": [[0, 0, "Linear"], [4, 0, "Quad In"], [14, 1]]},
        },
        "Sparks": {
            "Kind": "Emitter", "On": "CutAt", "From": "Cut", "Image": "fx_spark",
            "Why": "A burst off the cut, thrown on along her line, away from where she was.",
            "Emit": [[0, 10]],
            "Emitter": {"Lifetime": [0.15, 0.3], "Speed": [10, 18], "SpreadAngle": [30, 30], "EmissionDirection": "Front",
                        "Drag": 8, "Acceleration": v3((0, -6, 0)), "Size": [[0, 0.55], [1, 0]],
                        "Transparency": [[0, 0], [0.7, 0], [1, 1]], "Rotation": [0, 360], "LightEmission": 1,
                        "LightInfluence": 0},
            "Tracks": {},
        },
        "CutLight": {
            "Kind": "Light", "On": "CutAt", "From": "Cut", "Range": 10, "Color": WHITE,
            "Why": "A light on the cut, lit at once and eased out.",
            "Tracks": {"Brightness": [[0, 5, "Quad Out"], [16, 0]]},
        },
    }
    return {"Schema": "rows/1", "Effect": name, "Why": why, "Area": 1, "Grey": True, "Action": ACTION, "Free": "Cut",
            "Rows": rows}, lengths


def check(effect_rows):
    """Config.EffectRows' and the rows cases' own tests that run without the game; the rest run when Faber takes it."""
    names = set(re.findall(r"^\s*(\w+)\s*=\s*\{", FXKIT.read_text(encoding="utf-8"), flags=re.M))
    problems = [f"{w} isn't in Config.FxKit" for w in IMAGES + MESHES if w not in names]
    problems += [f"top field {k}" for k in effect_rows if k not in TOP]
    rows = effect_rows["Rows"]
    for name, row in rows.items():
        problems += [f"{name}: field {k}" for k in row if k not in FIELDS]
        if row["Kind"] not in KINDS:
            problems.append(f"{name}: kind {row['Kind']}")
        if "On" in row and ("Body" in row or row["On"] not in rows or row["On"] == name):
            problems.append(f"{name}: rides {row['On']}")
        for ref in (row.get("Low"), row.get("High")):
            if ref and (ref.split(".")[0] not in rows or rows[ref.split(".")[0]]["Kind"] != "Beam"):
                problems.append(f"{name}: hangs on {ref}")
        if row["Kind"] == "Beam" and not ({"Trail", "Low", "On", "Body"} & set(row) or "Foot" in row["Tracks"]):
            problems.append(f"{name}: a beam with no ends")
        if row["Kind"] in ("Beam", "Card", "Emitter") and row.get("Image") not in names:
            problems.append(f"{name}: image {row.get('Image')}")
        if row.get("Taper") is not None and not 0 < row["Taper"] <= 1:
            problems.append(f"{name}: taper")
        for track, keys in row["Tracks"].items():
            for i, key in enumerate(keys):
                how = key[2] if len(key) > 2 else None
                parts = (how or "").split()
                if how not in (None, "Linear") and not (len(parts) == 2 and parts[0] in STYLES and parts[1] in ("In", "Out", "InOut")):
                    problems.append(f"{name}.{track}: ease {how}")
                if i and key[0] < keys[i - 1][0]:
                    problems.append(f"{name}.{track}: keys out of order")
    return problems


def write_rows(out):
    n = measure()
    knot16 = landed(n["line"][LAND]["knot"])
    shade = n["shade"]
    reach = math.hypot(shade[0] - knot16[0], shade[2] - knot16[2])
    flank = math.degrees(math.atan2(FLANK, reach))

    def far_x(deg):  # the scarf's far end, turned, in the effect's foot's frame: its x
        s = n["line"][24]
        return landed(add(s["knot"], rot(turned_about_up(deg), sub(s["tip"], s["knot"]))))[0]

    turn_b = max((flank, -flank), key=lambda deg: far_x(deg) * CAMERA_SIDE)
    why_a = ("Kirra's Scarf Step, the grey block, take A: the line on the scarf, through the Shade's chest (AR10, "
             "section 5, and research's technique check). Written by tools/blender/kirra_scarf_step_fx.py from the clip.")
    why_b = ("Kirra's Scarf Step, the grey block, take B: the line turned past the Shade's flank on the player's camera's "
             f"side ({FLANK} studs off its middle); the rest is take A. Judged beside A at 64 px: if either reads as a "
             "skewer, the flank is taken and the clip's aim follows. Written by tools/blender/kirra_scarf_step_fx.py.")
    rows_a, lengths = effect(n, ACTION, why_a, 0.0)
    rows_b, _ = effect(n, ACTION + "Flank", why_b, turn_b)
    out.mkdir(parents=True, exist_ok=True)
    for eff in (rows_a, rows_b):
        problems = check(eff)
        if problems:
            raise SystemExit(f"{eff['Effect']}: " + "; ".join(problems))
        path = out / f"{eff['Effect']}.rows.json"
        path.write_text(json.dumps(eff, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {path}")
    print("in her root's frame (x right, y up from the root's centre, z back):")
    for f in KEYS:
        s = n["line"][f]
        d = sub(s["tip"], s["knot"])
        print(f"  {f}: knot ({s['knot'][0]:.2f}, {s['knot'][1]:.2f}, {s['knot'][2]:.2f}), knot to tip {length(d):.2f} studs,"
              f" aim ({unit(d)[0]:.2f}, {unit(d)[1]:.2f}, {unit(d)[2]:.2f})")
    for label, deg in (("A", 0.0), ("B", turn_b)):
        s = n["line"][24]
        d = unit(rot(turned_about_up(deg), sub(s["tip"], s["knot"])))
        k = landed(s["knot"])
        far = landed(add(s["knot"], mul(d, 1.0)))
        step = sub(far, k)
        u = (shade[2] - k[2]) / step[2]
        at = add(k, mul(step, u))
        print(f"  take {label}: turned {deg:+.1f} degrees at her knot; it passes the Shade's middle {at[0] - shade[0]:+.2f} "
              f"studs to the side, {at[1]:.2f} up (its chest {shade[1]:.2f}), {u:.2f} studs from her knot")
    print(f"  her knot at Land, in the effect's foot's frame: ({knot16[0]:.2f}, {knot16[1]:.2f}, {knot16[2]:.2f}); "
          f"the Shade's chest ({shade[0]:.2f}, {shade[1]:.2f}, {shade[2]:.2f}), {reach:.2f} studs on")
    print(f"  the line's Top, held: {rows_a['Rows']['Line']['Tracks']['Top'][0][1]} studs; its lengths keyed "
          + ", ".join(f"{v:.2f}" for v in lengths))
    return n, rows_a, rows_b


# --- the preview, in Blender --------------------------------------------------------------------------------------------

STRIP = (12, 13, 14, 16, 18, 20, 24, 32, 38, 42, 44, 46, 52, 60)


def preview(out):
    import bpy
    import numpy as np
    from mathutils import Matrix, Vector

    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import fx_kit as kit
    import kirra_clips as kc
    import r6anim as r6
    import rook_clips as rc

    n, rows_a, rows_b = write_rows(out)
    scene, rig, costume, undress, feet, ctl, motors, rest, extra = kc.build()
    take = kc.Take(rig, feet, ctl, "ScarfStep", 1000 * list(kc.CLIPS).index("ScarfStep"), rest)
    kc.scarf_step(take)
    rc.ground(rig, feet, [take])
    rc.lift(rig, ctl["lift"], [take])
    kc.props(rig, ctl, motors, rest, [take])
    kc.stand_ins([take])
    cam = kc.cameras(scene, [take])[take.name, "game"]
    scene.frame_set(take.start)
    m0 = r6.to_roblox(rig.root.matrix_world)
    foot = m0.to_translation() - Vector((0, ROOT_HEIGHT, 0))
    look = -(m0.to_3x3().normalized() @ Vector((0, 0, 1)))
    look.y = 0
    look.normalize()
    right = look.cross(Vector((0, 1, 0))).normalized()
    basis = Matrix((right, (0, 1, 0), -look)).transposed()

    line_mesh = bpy.data.meshes.new("Fx.Line")
    line_mesh.materials.append(r6.flat_material("ScarfStepLine", (0.95, 0.95, 0.95), roughness=1.0, emission=(0.95, 0.95, 0.95)))
    line = bpy.data.objects.new("Fx.Line", line_mesh)
    bm = kit.crescent()
    cres_mesh = bpy.data.meshes.new("FxCrescent")
    bm.to_mesh(cres_mesh)
    bm.free()
    cres_mesh.materials.append(r6.flat_material("ScarfStepCrescent", (0.77, 0.77, 0.77), roughness=1.0))
    crescent = bpy.data.objects.new("Fx.Crescent", cres_mesh)
    for obj in (line, crescent):
        scene.collection.objects.link(obj)
        obj.display.show_shadows = False
    state = {"rows": None, "crescent": False}

    def place(scene, *_):
        if state["rows"] is None:
            return
        f = scene.frame_current - take.start
        rows = state["rows"]["Rows"]
        tracks = rows["Line"]["Tracks"]
        t = f - LAND
        line_mesh.clear_geometry()
        width, fade, top = value(tracks["Width"], t), value(tracks["Transparency"], t), value(tracks["Top"], t)
        if width is not None and fade is not None and fade < 0.99 and top and top > 0.01:
            m = r6.to_roblox(rig.root.matrix_world)
            root, turn = m.to_translation(), m.to_3x3().normalized()
            low = root + turn @ Vector(value(tracks["At"], t))
            high = low + turn @ Vector(up_of(value(tracks["Tilt"], t))) * top
            eye = r6.point_to_roblox(scene.camera.matrix_world.translation)
            side = (high - low).cross(eye - (low + high) / 2).normalized()
            w0, w1 = width / 2, width * TAPER / 2
            quad = [low - side * w0, low + side * w0, high + side * w1, high - side * w1]
            line_mesh.from_pydata([tuple(r6.point_to_blender(p)) for p in quad], [], [(0, 1, 2, 3)])
        line_mesh.update()
        c = rows["Crescent"]
        tc = f - CUT
        fade = value(c["Tracks"]["Transparency"], tc)
        crescent.hide_render = not (state["crescent"] and fade is not None and fade < 0.6)
        if not crescent.hide_render:
            at = Vector(value(rows["CutAt"]["Tracks"]["At"], tc))
            spin = value(c["Tracks"]["Spin"], tc) or 0.0
            sx, sy, sz = value(c["Tracks"]["Scale"], tc)
            tx, ty, tz = c["Turn"]["Vector3"]
            m = (Matrix.Translation(foot + basis @ at) @ basis.to_4x4()
                 @ Matrix.Rotation(math.radians(spin), 4, "Y")
                 @ Matrix.Rotation(math.radians(ty), 4, "Y") @ Matrix.Rotation(math.radians(tx), 4, "X")
                 @ Matrix.Rotation(math.radians(tz), 4, "Z") @ Matrix.Diagonal((sx, sy, sz, 1.0)))
            crescent.matrix_world = r6.to_blender(m)

    bpy.app.handlers.frame_change_post.append(place)

    def sheet(path, with_crescent):
        state["crescent"] = with_crescent
        parts = []
        for size, labelled in (((220, 250), True), ((56, 64), False)):
            for name, eff in (("A", rows_a), ("B", rows_b)):
                state["rows"] = eff
                scene.render.resolution_x, scene.render.resolution_y = size
                tmp = out / f"_{path.stem}_{name}_{size[1]}.png"
                r6.render_shots(scene, [(cam, take.start + f, f"{name} {f}" if labelled else "") for f in STRIP], tmp,
                                columns=len(STRIP))
                scene.render.stamp_font_size = 13
                image = bpy.data.images.load(str(tmp))
                parts.append(np.array(image.pixels[:], dtype=np.float32).reshape(image.size[1], image.size[0], 4))
                bpy.data.images.remove(image)
                tmp.unlink()
        full = max(p.shape[1] for p in parts)
        parts = [np.concatenate([p, np.zeros((p.shape[0], full - p.shape[1], 4), np.float32)], axis=1) for p in parts]
        whole = np.concatenate(list(reversed(parts)), axis=0)
        image = bpy.data.images.new(path.stem, whole.shape[1], whole.shape[0], alpha=True)
        image.pixels = whole.ravel()
        image.filepath_raw, image.file_format = str(path), "PNG"
        image.save()
        bpy.data.images.remove(image)
        print(f"wrote {path}")

    sheet(out / "scarf_step_line.png", False)
    sheet(out / "scarf_step_crescent.png", True)


def main():
    if "--" in sys.argv:  # in Blender
        args = sys.argv[sys.argv.index("--") + 1:]
        out = Path(args[0])
        if args[1:2] == ["rows"]:
            write_rows(out)
        else:
            preview(out)
        return
    if len(sys.argv) < 3 or sys.argv[1] != "rows":
        print(__doc__)
        sys.exit(2)
    write_rows(Path(sys.argv[2]))


if __name__ == "__main__":
    main()
