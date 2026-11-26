"""The Shades' tells (AR52, "Scintilla's looks"): the Guard's ward and the Dasher's lane, written as rows files for
tools/fx/rows_take.py. Scintilla's, the effect family's one script. Built to research's pick of 2026-11-26 (G2 ward, D1
lane; their targets in build/handoff/Shade/targets/, drawn by tools/fx/shade_targets.py), in their colours.

    py tools/fx/shade_tells.py [out_dir]        (default: build/handoff/Shade/fx)
    py tools/fx/rows_take.py build/handoff/Shade/fx/<Effect>.rows.json ...

GuardShield and DasherLine are their actions' own effects (Definitions.Actions' Effect on GuardRaise and DasherLunge).

The Guard. Feel line: a Guard shuts its sleeves and a curved paper shield of light snaps up before it, ribbed like a
lantern; your fighter's blows skate off it in sparks where they land, until a heavy one tears it open into paper and
light. Research's condition (AR52, its pass in the game): it reads as raised apart from the mask, never as a bigger face,
and a glance shows itself where the hit lands. At the quarter: the ribs read as paper and lantern, or it's any game's ring.
- GuardShield, GuardRaise's own effect, on its beats, riding the root: the ward (G2), a disc 3.8 across before the Guard's
  chest, domed a little toward the blow: the kit's shell on the lantern's ribs, tinted azure (six ribs across it), seen
  through. Under it, the hue laid deep (Neon, so the sun never pales it), the target's technique for the pale deck. Its
  rim, the kit's hoop stood up facing the blow a hair wider than the paper, Neon: a thin closed white line round the
  edge; beside it the halo, a wider, deeper hoop in the hue, the rim's blue glow. A glow card at its middle, its boss.
  It snaps up in the eight frames before Raise (Back Out), breathes through the hold, and folds down over eight frames
  from Drop. The halo flashes on Raise, the click of it shutting (the target's click). A break ends the action, and with
  it the ward at once: GuardBreak takes its place.
- GuardGlance, played by the builder's hook on each glance, anchored where the blow meets the ward, its Front the way
  the blow travels: a glint where it lands and pale azure needles skating back off it toward the attacker.
- GuardBreak, played by the hook on the break, anchored at the ward's middle the same way: a ring and a puff, an azure
  light, and six chips of light flung out and on along the blow, turning, gone by a third of a second.

The Dasher. Feel line: a Dasher folds behind its mask and a blade of light cuts open along the street to your fighter,
filling toward you like a fuse; then the Dasher is down it in a streak, and a slash bursts where it lands.
- DasherLine, DasherLunge's own effect, on its beats. Every row rides the Dasher's root and is held where it first shows
  (Hold), so the line stays on the stone, laid along the aim fixed at Line, while the Dasher runs down it.
  - Lane (Line): the hit's own lane drawn flat on the street: every point within 2 studs (Half) of the line from the
    Dasher's feet to 14 studs on (Most and Past), so a plate 4 across and two round ends (LaneNear, LaneFar: the kit's
    shell flattened to a disc), laid faint deep amber. Drawn as what hits, so nobody is hit off it (Faber's review).
  - The edges, the hero (D1): two clean lines of amber Neon with a white core, down both sides (EdgeLeft, EdgeRight) and
    round both ends in six strokes each (CapNear1..6, CapFar1..6), where the hit's reach ends. They cut open across in
    four frames.
  - Fuse (Line to Land): a brighter blade inside it in six pieces of amber Neon, lit in turn from the Dasher's feet, the
    last on Land: the time left to move. Each piece is held where it was laid at Line and shown by its fade, since a
    held row's place is set once. All close over six frames after Land.
  - Streak (Lunge to Land): a hot amber trail behind the Dasher's root as it runs.
  - Slash (Land): the crescent sheet where it lands, with hot amber needles on along the run.
  World: the rows draw at the studs written, never the body's scale, since the hit's lane is 14 by 4 for an elite too.

Frames at 60 a second from each row's beat. The colours passed their content check on 2026-11-26 (AR52): nothing red,
the chips light, never dark or liquid, nothing left behind (AGENTS.md, rule 4).
"""
import json
import math
import sys
from pathlib import Path

from hit_sparks import c3, needles, sheet_rows, v3

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "handoff" / "Shade" / "fx"

ROOT_HEIGHT = 3  # an R6 root over the floor, studs
LINE_LENGTH = 12 + 2  # what the hit takes: Actions.DasherLunge's Moves.Lunge.Most, and Config.Combat.Dasher.Line.Past
LINE_HALF = 2  # Config.Combat.Dasher.Line.Half: the hit takes a centre within 2 studs of the line
LINE_TO_LAND = round((1.25 - 0.2667) * 60)  # frames from the Line beat to Land: 59
RAISE_TO_DROP = round((2.3 - 0.3) * 60)  # frames from Raise to Drop: 120
FLOOR = -ROOT_HEIGHT + 0.04  # a hair over the street, from the root

# The picked targets' colours (AR52: G2 ward and D1 lane, research's pick of 2026-11-26; tools/fx/shade_targets.py).
AZURE = (63, 140, 255)  # the ward's light
AZURE_RIM = (200, 226, 255)  # its rim, Neon: a white core with the hue in it
AZURE_DEEP = (22, 60, 140)  # the target's #163C8C, laid under the light, so the ward holds on the pale deck
DEEP_FILL = 0.68  # the deep layer's Transparency: the target lays it at 0.32
PAPER_SEEN = 0.65  # the paper's Transparency through the hold: seen through to the mask, as the target's middle
HALO_BAND = 0.3  # studs: the halo's band toward the Guard, its strip beside the rim from the quarter's camera
HALO_SEEN = 0.4  # the halo's Transparency through the hold, after its flash on Raise
AMBER = (255, 154, 31)  # the lane's light, Neon in its edges and fuse
AMBER_CORE = (255, 232, 196)  # the edges' white core
AMBER_DEEP = (122, 58, 0)  # laid under the light, so the lane holds on the pale deck
AMBER_HOT = (255, 206, 140)  # the run's streak, the landing's needles
GUARD_AT = (0, 0.7, -1.6)  # the ward's middle from the root: Config.Combat.Guard.Look's Ahead 1.6, Up 0.4, and the
# target's 0.3 more (shade_targets.draw_guard)
WARD = 1.9  # its radius


def at_beat(rows, prefix, beat, frame=0):
    """A sheet's three passes let go on `frame` of `beat`."""
    for name in ("Line", "Fill", "Dark"):
        row = rows[f"{prefix}{name}"]
        row["From"] = beat
        row["Emit"] = [[frame, 1]]
        row["Tracks"] = {"At": [[frame, row["Tracks"]["At"][0][1]]]}
    return rows


def ride(rows, body="HumanoidRootPart", hold=False, at=None):
    for row in rows.values():
        row["Body"] = body
        if hold:
            row["Hold"] = True
        if at is not None and row["Kind"] != "Mesh" and row["Kind"] != "Beam":
            row["Tracks"]["At"] = [[key[0], at] for key in row["Tracks"]["At"]]
    return rows


def effect(name, why, rows, action=None, world=False):
    data = {"Schema": "rows/1", "Effect": name, "Why": why, "Area": 1, "Grey": False}
    if action:
        data["Action"] = action
    if world:  # drawn in studs as written, whatever the body's scale: the hit's lane is the same for an elite
        data["World"] = True
    data["Rows"] = rows
    return data


def guard_shield():
    c = GUARD_AT
    d = RAISE_TO_DROP
    at = [[-8, v3(*c), "Linear"], [d, v3(*c), "Quad In"], [d + 8, v3(c[0], c[1] - 1.0, c[2])]]
    full = (WARD, WARD, 0.12)  # times the shell's unit 2: a disc 3.8 across, domed a quarter stud toward the blow

    def grows(x, y, z, flat=0.03):  # snapped up in the eight frames before Raise, breathing, folded down after Drop
        return [[-8, v3(x * 0.2, y * 0.2, flat), "Back Out"], [0, v3(x, y, z), "Sine InOut"],
                [d // 2, v3(x * 1.02, y * 1.02, z), "Sine InOut"], [d, v3(x, y, z), "Quad In"], [d + 8, v3(x * 1.08, 0.12, flat)]]

    def back(by):  # the ward's place, `by` studs on toward the Guard (+Z): behind the paper, so it's drawn under it
        return [[key[0], v3(key[1]["Vector3"][0], key[1]["Vector3"][1], key[1]["Vector3"][2] + by)] + key[2:] for key in at]

    def stood(radius, band):  # the hoop stood up facing the blow, its band `band` studs deep toward the Guard
        return [[key[0], v3(key[1]["Vector3"][0] * radius, band / 0.3, key[1]["Vector3"][1] * radius)] + key[2:]
                for key in grows(WARD, WARD, 0.12)]

    def click(keys):  # opened a twentieth wider on Raise, back over five frames: the snap of it shutting
        wide = [0, v3(keys[1][1]["Vector3"][0] * 1.06, keys[1][1]["Vector3"][1], keys[1][1]["Vector3"][2] * 1.06), "Quad Out"]
        return [keys[0], wide, [5] + keys[1][1:]] + keys[2:]

    # By day the paper carried the hue alone, lit by the sun and seen through to the pale deck, and read pale icy cyan
    # (the build beside its target, 2026-11-26). The target's own technique: the hue laid deep under the light.
    deep = {
        "Kind": "Mesh",
        "From": "Raise",
        "Part": ["FxShell"],
        "Color": c3(AZURE_DEEP),
        "Tracks": {
            "At": back(0.04),
            "Scale": grows(WARD * 0.98, WARD * 0.98, 0.1),
            "Transparency": [[-8, 0.9, "Quad Out"], [0, DEEP_FILL, "Sine InOut"], [d, DEEP_FILL, "Quad In"], [d + 8, 1]],
        },
        "Why": "the ward's hue laid deep under its light, Neon so the sun never pales it: it holds on the pale deck",
    }
    shield = {
        "Kind": "Mesh",
        "From": "Raise",
        "Part": ["FxShell"],
        "Look": "fx_ribs_Grey",
        "Grey": "fx_ribs_Grey",
        "Color": c3(AZURE),
        "Tracks": {
            "At": at,
            "Scale": grows(*full),
            "Transparency": [[-8, 0.8, "Quad Out"], [0, PAPER_SEEN, "Sine InOut"], [d, PAPER_SEEN, "Quad In"], [d + 8, 1]],
            "Glow": [[-8, 3, "Quad Out"], [5, 1.3, "Sine InOut"], [d, 1.3]],
        },
        "Why": "the hero: the ward, a disc of lantern paper in azure, six ribs across it, before the Guard's chest, seen through",
    }
    # the rim: a closed line of white light round the paper, its band toward the Guard
    rim = {
        "Kind": "Mesh",
        "From": "Raise",
        "Part": ["FxHoop"],
        "Color": c3(AZURE_RIM),
        "Tracks": {
            "At": back(0.03),
            "Tilt": [[-8, v3(90, 0, 0)]],
            "Scale": stood(1.04, 0.06),
            "Transparency": [[-8, 0.6, "Quad Out"], [0, 0, "Linear"], [6, 0.1, "Sine InOut"], [d, 0.15, "Quad In"], [d + 8, 1]],
        },
        "Why": "the ward's rim: a closed line of white light round the paper",
    }
    # the halo: the rim's blue glow, a hoop a little wider and deeper in the hue, so from the quarter's camera its band
    # shows beside the white line as the target's azure edge. Its flash on Raise is the click (the target's: the rim
    # 2.6 times brighter, gone over five frames), where a ring of the kit's grey sheet read grey with a dark edge by day.
    halo = {
        "Kind": "Mesh",
        "From": "Raise",
        "Part": ["FxHoop"],
        "Color": c3(AZURE),
        "Tracks": {
            "At": back(0.05),
            "Tilt": [[-8, v3(90, 0, 0)]],
            "Scale": click(stood(1.08, HALO_BAND)),
            "Transparency": [[-8, 0.8, "Quad Out"], [0, 0, "Quad Out"], [5, HALO_SEEN, "Sine InOut"], [d, HALO_SEEN, "Quad In"], [d + 8, 1]],
        },
        "Why": "the rim's blue glow, flashed on Raise: the click of the ward shutting",
    }
    boss = {
        "Kind": "Card",
        "From": "Raise",
        "Image": "fx_glow",
        "Color": c3(AZURE),
        "Tracks": {
            "At": [[key[0], v3(key[1]["Vector3"][0], key[1]["Vector3"][1], key[1]["Vector3"][2] - 0.3)] + key[2:] for key in at],
            "Size": [[-4, 0.8, "Back Out"], [0, 3.0, "Sine InOut"], [d, 2.8, "Quad In"], [d + 8, 0]],
            "Transparency": [[-4, 0.3, "Quad Out"], [6, 0.7, "Sine InOut"], [d, 0.7]],
            "Brightness": [[-4, 2, "Quad Out"], [6, 1.2]],
        },
        "Why": "the boss: the ward lit to its middle, in its hue",
    }
    rows = {"Deep": deep, "Shield": shield, "Rim": rim, "Halo": halo, "Boss": boss}
    ride(rows)
    return effect("GuardShield", "The Guard's raised ward, GuardRaise's own effect: research's pick, G2 (AR52).",
                  rows, action="GuardRaise")


def guard_glance():
    rows = {
        **sheet_rows("Glint", "glint", 0.22, [[0, 1.2], [0.15, 1.8], [1, 1.6]], 0.85, 30,
                     "where the blow meets the paper: a glint, small, a glance and not a hit"),
        "Skate": needles(5, [18, 28], [0.1, 0.18], 75, 0.7, 0, direction="Back", colour=AZURE_RIM),
    }
    rows["Skate"]["Why"] = "the needles skating back off the shield toward the attacker: the blow turned aside"
    return effect("GuardGlance", "A blow glancing off the Guard's ward, at the hook's anchor (AR52, G2).", rows)


def guard_break():
    rows = {
        **sheet_rows("Tear", "ring", 0.32, [[0, 2.4], [1, 5]], 0.34, 0,
                     "the shield torn open: a ring out from its middle"),
        **sheet_rows("Puff", "puff", 0.45, [[0, 2], [1, 3.4]], 0.45, 40,
                     "the paper's dust where it was, a breath after"),
        "Light": {
            "Kind": "Light",
            "Range": 7,
            "Color": c3(AZURE),
            "Tracks": {"At": [[0, v3(0, 0, 0.5)]], "Brightness": [[0, 2.5, "Quad Out"], [8, 0]]},
            "Why": "the break lights the Guard for a moment",
        },
    }
    for key in ("PuffLine", "PuffFill", "PuffDark"):
        rows[key]["Emit"] = [[2, 1]]
        rows[key]["Tracks"] = {"At": [[2, v3(0, 0, 0)]]}
    # six chips of the paper, flung out across the shield and on along the blow (-Z), turning, gone by 20 frames
    outs = [(-1.8, 1.4), (1.9, 1.1), (-2.2, -0.4), (2.0, -0.7), (-0.6, 2.0), (0.8, -1.6)]
    for index, (x, y) in enumerate(outs, start=1):
        chip = f"FxChip{(index - 1) % 3 + 1}"
        rows[f"Chip{index}"] = {
            "Kind": "Mesh",
            "Part": [chip],
            "Color": c3(AZURE_RIM if index % 2 else AZURE),
            "Tracks": {
                "At": [[0, v3(x * 0.25, y * 0.25, 0), "Quad Out"], [16, v3(x, y - 0.6, -1.6 - index * 0.15)]],
                "Scale": [[0, 0.9, "Linear"], [20, 0.5]],
                "Spin": [[0, index * 40, "Quad Out"], [20, index * 40 + (220 if index % 2 else -220)]],
                "Tilt": [[0, v3(index * 25, 0, 0), "Quad Out"], [20, v3(index * 25 + 160, 0, 90)]],
                "Transparency": [[0, 0, "Quad In"], [12, 0.1, "Quad In"], [20, 1]],
            },
            "Why": "a chip of the ward, light and paper, flung out and on along the blow, turning",
        }
    return effect("GuardBreak", "The Guard's ward broken, at the hook's anchor (AR52, G2).", rows)


def dasher_line():
    n = LINE_TO_LAND
    laid = {"Look": "fx_rise_Grey", "Grey": "fx_rise_Grey", "Color": c3(AMBER_DEEP)}

    def open_close(wide, deep, long):  # cut open across in four frames, held, closed across over six after Land
        return [[0, v3(0.02, deep, long), "Back Out"], [4, v3(wide, deep, long), "Linear"], [n, v3(wide, deep, long), "Quad In"],
                [n + 6, v3(0.02, deep, long)]]
    # the lane: what the hit takes, every point within Half of the line from the feet to Most + Past, so a stadium: a
    # plate down the line, and a disc of the shell flattened at each end. Laid deep and faintly lit, at the target's
    # strength (the content check of 2026-11-26: never a dark red-brown patch on the slate), so the light holds on the
    # pale deck. The discs, laid over the plate's ends, are fainter, so the overlap stays near the plate's own.
    rows = {
        "Lane": {"Kind": "Mesh", "From": "Line", "Part": ["FxPlate"], **laid, "Tracks": {
            "At": [[0, v3(0, FLOOR, -LINE_LENGTH / 2)]], "Scale": open_close(2 * LINE_HALF, 0.04, LINE_LENGTH),
            "Transparency": [[0, 0.75, "Linear"], [n, 0.78, "Quad In"], [n + 6, 1]], "Glow": [[0, 2.5, "Quad Out"], [4, 1.5]]},
            "Why": "the lane, laid: a faint amber stadium on the street, as wide and as long as what the hit takes"},
    }
    for key, z in (("LaneNear", 0), ("LaneFar", -LINE_LENGTH)):
        rows[key] = {"Kind": "Mesh", "From": "Line", "Part": ["FxShell"], **laid, "Tracks": {
            "At": [[0, v3(0, FLOOR - 0.01, z)]], "Scale": open_close(LINE_HALF, 0.02, LINE_HALF),
            "Transparency": [[0, 0.82, "Linear"], [n, 0.84, "Quad In"], [n + 6, 1]], "Glow": [[0, 2.5, "Quad Out"], [4, 1.5]]},
            "Why": "the lane's round end, laid: the hit reaches Half past the line's end and behind the feet"}
    # the fuse: six pieces of a brighter, narrower blade inside it, from the feet to the line's end, each showing in turn
    # so the whole is lit on Land, the time left to move. Each is placed at Line, held there (Hold places a row once,
    # when it first shows), and shown by its fade alone. Neon, so the pieces join as one even blade.
    steps = 6
    piece = LINE_LENGTH / steps
    lit_at = 0.35  # a lit piece's transparency
    for k in range(1, steps + 1):
        lit, full = round(n * (k - 1) / steps), round(n * k / steps)
        rows[f"Fuse{k}"] = {"Kind": "Mesh", "From": "Line", "Part": ["FxPlate"], "Color": c3(AMBER), "Tracks": {
            "At": [[0, v3(0, FLOOR + 0.02, -(k - 0.5) * piece)]],
            "Scale": open_close(LINE_HALF * 1.6, 0.02, piece),
            "Transparency": ([[0, 1, "Linear"]] if lit > 0 else []) + [[lit, 1, "Quad Out"]] + ([[full, lit_at, "Linear"]] if full < n else [])
            + [[n, lit_at, "Quad In"], [n + 6, 1]]},
            "Why": f"the fuse's piece {k} of {steps}: lit in turn from the feet, the whole blade lit on Land"}
    # the edges: the hero (research's pick, D1): two clean lines of light round the stadium where the hit takes, each a
    # Neon stroke in amber with a white core on it, straight down both sides and round both ends in six strokes each
    width, core = 0.16, 0.05

    def stroke(name, x, z, long, turn, why):
        for suffix, wide, lift, colour in (("", width, 0.04, AMBER), ("Core", core, 0.05, AMBER_CORE)):
            rows[f"{name}{suffix}"] = {"Kind": "Mesh", "From": "Line", "Part": ["FxPlate"], "Color": c3(colour), "Tracks": {
                "At": [[0, v3(round(x, 4), FLOOR + lift, round(z, 4))]], "Spin": [[0, round(turn, 3)]],
                "Scale": open_close(wide, 0.02, round(long, 4)),
                "Transparency": [[0, 0, "Linear"], [n, 0.1, "Quad In"], [n + 6, 1]]},
                "Why": why if not suffix else why + ": its white core"}
    for side, x in (("Left", -LINE_HALF), ("Right", LINE_HALF)):
        stroke(f"Edge{side}", x, -LINE_LENGTH / 2, LINE_LENGTH + width / 2, 0, f"the lane's {side.lower()} edge: where the hit's reach ends")
    ends = 6  # strokes round each end
    chord = 2 * LINE_HALF * math.sin(math.pi / (2 * ends))
    mid = LINE_HALF * math.cos(math.pi / (2 * ends))
    for k in range(ends):
        a = math.pi * (k + 0.5) / ends  # the stroke's middle, round the end from the right side
        stroke(f"CapFar{k + 1}", mid * math.cos(a), -LINE_LENGTH - mid * math.sin(a), chord + width / 2, math.degrees(a),
               "the far end's edge, round: the hit reaches Half past the line's end")
        stroke(f"CapNear{k + 1}", mid * math.cos(a), mid * math.sin(a), chord + width / 2, -math.degrees(a),
               "the near end's edge, round, behind the feet")
    streak = {
        "Kind": "Beam",
        "From": "Lunge",
        "Body": "HumanoidRootPart",
        "Image": "fx_beam",
        "Grey": "fx_beam",
        "Color": c3(AMBER_HOT),
        "Beam": {"FaceCamera": True, "LightEmission": 1, "LightInfluence": 0, "TextureMode": "Stretch", "TextureSpeed": 0, "Segments": 1},
        "Trail": {"Back": 0.3, "Beyond": 0},
        "Tracks": {
            "At": [[0, v3(0, -0.6, 0)]],
            "Width": [[0, 1.2, "Linear"], [15, 1.2, "Quad In"], [24, 0]],
            "Lag": [[0, 6]],
            "Transparency": [[0, 0.1, "Quad In"], [24, 1]],
        },
        "Why": "the run: a streak behind the Dasher down its line, gone soon after it lands",
    }
    slash = at_beat(sheet_rows("Slash", "crescent", 0.3, [[0, 3], [0.15, 4.2], [1, 4.6]], 0.3, 0,
                               "where it lands: the crescent sheet across the run"), "Slash", "Land")
    ride(slash, hold=True, at=v3(0, 0, -0.8))
    on = needles(6, [26, 40], [0.12, 0.2], 35, 1.0, 0, colour=AMBER_HOT)
    on["From"] = "Land"
    on["Body"] = "HumanoidRootPart"
    on["Hold"] = True
    on["Tracks"]["At"] = [[0, v3(0, 0, -0.8)]]  # from the slash, in front of the body (the content check, AR52)
    on["Why"] = "needles on along the run as it lands"
    for row in rows.values():  # the lane and the fuse stay on the stone where the line was laid
        row["Body"] = "HumanoidRootPart"
        row["Hold"] = True
    rows.update({"Streak": streak, **slash, "On": on})
    return effect("DasherLine", "The Dasher's line, DasherLunge's own effect: research's pick, D1 (AR52).", rows, action="DasherLunge", world=True)


def build():
    return {e["Effect"]: e for e in (guard_shield(), guard_glance(), guard_break(), dasher_line())}


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else OUT
    out.mkdir(parents=True, exist_ok=True)
    for name, data in build().items():
        path = out / f"{name}.rows.json"
        path.write_bytes((json.dumps(data, indent=2) + "\n").encode("utf-8"))  # LF, as the repo keeps it
        print(f"wrote {path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else path}")


if __name__ == "__main__":
    main()
