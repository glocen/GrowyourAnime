"""The Shades' tells (AR52, "Scintilla's looks"): the Guard's shield and the Dasher's line, written as rows files for
tools/fx/rows_take.py, in grey. Scintilla's, the effect family's one script.

    py tools/fx/shade_tells.py [out_dir]        (default: build/handoff/Shade/fx)
    py tools/fx/rows_take.py build/handoff/Shade/fx/GuardGlance.rows.json build/handoff/Shade/fx/GuardBreak.rows.json

GuardShield and DasherLine are their actions' own effects, so the rows' logic case takes them only once GuardRaise and
DasherLunge name them as their Effect (Definitions.Actions): the builder takes those two with that line, in one commit.

The Guard. Feel line: a Guard shuts its sleeves and a curved paper shield of light snaps up before it, ribbed like a
lantern; your fighter's blows skate off it in sparks where they land, until a heavy one tears it open into paper and
light. Research's condition (AR52, its pass in the game): it reads as raised apart from the mask, never as a bigger face,
and a glance shows itself where the hit lands.
- GuardShield, GuardRaise's own effect (Action.Effect), on its beats: the hero is the kit's shell flattened to a lens,
  its near side bulging at the lead, a stud and a half before the Guard's chest, riding its root. It snaps up in the
  eight frames before Raise (Back Out), breathes a little through the hold, and folds down and out over eight frames
  from Drop. A ring snaps open on Raise, the click of it shutting. A break ends the action, and with it the shield at
  once: GuardBreak takes its place.
- GuardGlance, played by the builder's hook on each glance, anchored where the blow meets the shield, its Front the way
  the blow travels: a glint where it lands and needles skating back off the paper toward the attacker.
- GuardBreak, played by the hook on the break, anchored at the shield's middle the same way: a ring and a puff, and six
  paper chips flung out and on along the blow, turning, gone by a third of a second. Paper and light only.

The Dasher. Feel line: a Dasher folds behind its mask and a blade of light cuts open along the street to your fighter,
filling toward you like a fuse; then the Dasher is down it in a streak, and a slash bursts where it lands.
- DasherLine, DasherLunge's own effect, on its beats. Every row rides the Dasher's root and is held where it first shows
  (Hold), so the line stays on the stone, laid along the aim fixed at Line, while the Dasher runs down it.
  - Lane (Line): the hero, the hit's own lane drawn flat on the street: every point within 2 studs (Half) of the line
    from the Dasher's feet to 14 studs on (Most and Past), so a plate 4 across and two round ends (LaneNear, LaneFar:
    the kit's shell flattened to a disc). Drawn as what hits, so nobody is hit off it (Faber's review, 2026-11-26). It
    cuts open across in four frames.
  - Fuse (Line to Land): a brighter, narrower blade inside it in six pieces, lit in turn from the Dasher's feet, the
    last on Land: the time left to move. Each piece is held where it was laid at Line and shown by its fade, since a
    held row's place is set once. All close over six frames after Land.
  - Streak (Lunge to Land): a trail behind the Dasher's root as it runs.
  - Slash (Land): the crescent sheet where it lands, with needles on along the run.
  World: the rows draw at the studs written, never the body's scale, since the hit's lane is 14 by 4 for an elite too.

Frames at 60 a second from each row's beat. The block-in is Grey: every colour in its grey. The colours come after the
blockout's verdict. Nothing red, nothing left behind (AGENTS.md, rule 4).
"""
import json
import sys
from pathlib import Path

from hit_sparks import LINE, WARM, c3, needles, sheet_rows, v3

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "handoff" / "Shade" / "fx"

ROOT_HEIGHT = 3  # an R6 root over the floor, studs
LINE_LENGTH = 12 + 2  # what the hit takes: Actions.DasherLunge's Moves.Lunge.Most, and Config.Combat.Dasher.Line.Past
LINE_HALF = 2  # Config.Combat.Dasher.Line.Half: the hit takes a centre within 2 studs of the line
LINE_TO_LAND = round((1.25 - 0.2667) * 60)  # frames from the Line beat to Land: 59
RAISE_TO_DROP = round((2.3 - 0.3) * 60)  # frames from Raise to Drop: 120
FLOOR = -ROOT_HEIGHT + 0.04  # a hair over the street, from the root


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
    data = {"Schema": "rows/1", "Effect": name, "Why": why, "Area": 1, "Grey": True}
    if action:
        data["Action"] = action
    if world:  # drawn in studs as written, whatever the body's scale: the hit's lane is the same for an elite
        data["World"] = True
    data["Rows"] = rows
    return data


def guard_shield():
    front = v3(0, 0.4, -1.5)
    full = (1.8, 2.0, 0.42)  # times the shell's unit 2: 3.6 by 4 studs, 0.84 deep
    d = RAISE_TO_DROP
    shield = {
        "Kind": "Mesh",
        "From": "Raise",
        "Body": "HumanoidRootPart",
        "Part": ["FxShell"],
        "Look": "fx_ribs_Warm",
        "Grey": "fx_ribs_Grey",
        "Tracks": {
            "At": [[-8, front, "Linear"], [d, front, "Quad In"], [d + 8, v3(0, -1.2, -1.5)]],
            "Scale": [
                [-8, v3(0.4, 0.3, 0.08), "Back Out"],
                [0, v3(*full), "Sine InOut"],
                [d // 2, v3(full[0] * 1.03, full[1] * 1.03, full[2]), "Sine InOut"],
                [d, v3(*full), "Quad In"],
                [d + 8, v3(full[0] * 1.1, 0.15, 0.1)],
            ],
            "Transparency": [[-8, 0.8, "Quad Out"], [0, 0.25, "Sine InOut"], [d, 0.3, "Quad In"], [d + 8, 1]],
            "Glow": [[-8, 3, "Quad Out"], [4, 1.4, "Sine InOut"], [d, 1.4]],
        },
        "Why": "the hero: a lens of ribbed paper before the Guard, snapped up by Raise, held, folded down at Drop",
    }
    ring = at_beat(sheet_rows("Click", "ring", 0.3, [[0, 3], [1, 5]], 0.34, 0,
                              "the click of the shield shutting: a ring snapped open on Raise, round the shield"), "Click", "Raise")
    ride(ring, at=front)
    return effect("GuardShield", "The Guard's raised shield, GuardRaise's own effect: the grey block-in (AR52).",
                  {"Shield": shield, **ring}, action="GuardRaise")


def guard_glance():
    rows = {
        **sheet_rows("Glint", "glint", 0.22, [[0, 1.2], [0.15, 1.8], [1, 1.6]], 0.85, 30,
                     "where the blow meets the paper: a glint, small, a glance and not a hit"),
        "Skate": needles(5, [18, 28], [0.1, 0.18], 75, 0.7, 0, direction="Back"),
    }
    rows["Skate"]["Why"] = "the needles skating back off the shield toward the attacker: the blow turned aside"
    return effect("GuardGlance", "A blow glancing off the Guard's shield, at the hook's anchor: the grey block-in (AR52).", rows)


def guard_break():
    rows = {
        **sheet_rows("Tear", "ring", 0.32, [[0, 2.4], [1, 5]], 0.34, 0,
                     "the shield torn open: a ring out from its middle"),
        **sheet_rows("Puff", "puff", 0.45, [[0, 2], [1, 3.4]], 0.45, 40,
                     "the paper's dust where it was, a breath after"),
        "Light": {
            "Kind": "Light",
            "Range": 7,
            "Color": c3(WARM),
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
            "Color": c3(LINE),
            "Tracks": {
                "At": [[0, v3(x * 0.25, y * 0.25, 0), "Quad Out"], [16, v3(x, y - 0.6, -1.6 - index * 0.15)]],
                "Scale": [[0, 0.9, "Linear"], [20, 0.5]],
                "Spin": [[0, index * 40, "Quad Out"], [20, index * 40 + (220 if index % 2 else -220)]],
                "Tilt": [[0, v3(index * 25, 0, 0), "Quad Out"], [20, v3(index * 25 + 160, 0, 90)]],
                "Transparency": [[0, 0, "Quad In"], [12, 0.1, "Quad In"], [20, 1]],
            },
            "Why": "a chip of the shield's paper, flung out and on along the blow, turning",
        }
    return effect("GuardBreak", "The Guard's shield broken, at the hook's anchor: the grey block-in (AR52).", rows)


def dasher_line():
    n = LINE_TO_LAND
    grey = {"Look": "fx_rise_Warm", "Grey": "fx_rise_Grey"}
    open_close = lambda wide, deep, long: [  # cut open across in four frames, held, closed across over six after Land
        [0, v3(0.02, deep, long), "Back Out"], [4, v3(wide, deep, long), "Linear"], [n, v3(wide, deep, long), "Quad In"],
        [n + 6, v3(0.02, deep, long)]]
    fade = [[0, 0.1, "Linear"], [n, 0.25, "Quad In"], [n + 6, 1]]
    glow = [[0, 3, "Quad Out"], [4, 1.2, "Sine InOut"], [n, 1.6]]
    # the lane: what the hit takes, every point within Half of the line from the feet to Most + Past, so a stadium: a
    # plate down the line, and a disc of the shell flattened at each end
    rows = {
        "Lane": {"Kind": "Mesh", "From": "Line", "Part": ["FxPlate"], **grey, "Tracks": {
            "At": [[0, v3(0, FLOOR, -LINE_LENGTH / 2)]], "Scale": open_close(2 * LINE_HALF, 0.04, LINE_LENGTH),
            "Transparency": fade, "Glow": glow},
            "Why": "the hero: a blade of light cut open along the street, as wide and as long as what the hit takes"},
    }
    for key, z in (("LaneNear", 0), ("LaneFar", -LINE_LENGTH)):
        rows[key] = {"Kind": "Mesh", "From": "Line", "Part": ["FxShell"], **grey, "Tracks": {
            "At": [[0, v3(0, FLOOR, z)]], "Scale": open_close(LINE_HALF, 0.02, LINE_HALF), "Transparency": fade, "Glow": glow},
            "Why": "the lane's round end: the hit reaches Half past the line's end and behind the feet"}
    # the fuse: six pieces of a brighter, narrower blade inside it, from the feet to the line's end, each showing in turn
    # so the whole is lit on Land, the time left to move. Each is placed at Line, held there (Hold places a row once,
    # when it first shows), and shown by its fade alone.
    steps = 6
    piece = LINE_LENGTH / steps
    for k in range(1, steps + 1):
        lit, full = round(n * (k - 1) / steps), round(n * k / steps)
        rows[f"Fuse{k}"] = {"Kind": "Mesh", "From": "Line", "Part": ["FxPlate"], **grey, "Tracks": {
            "At": [[0, v3(0, FLOOR + 0.02, -(k - 0.5) * piece)]],
            "Scale": open_close(LINE_HALF * 0.8, 0.04, piece),
            "Transparency": ([[0, 1, "Linear"]] if lit > 0 else []) + [[lit, 1, "Quad Out"]] + ([[full, 0, "Linear"]] if full < n else []) + [[n, 0, "Quad In"], [n + 6, 1]],
            "Glow": [[0, 2, "Linear"], [n, 4]]},
            "Why": f"the fuse's piece {k} of {steps}: lit in turn from the feet, the whole blade lit on Land"}
    streak = {
        "Kind": "Beam",
        "From": "Lunge",
        "Body": "HumanoidRootPart",
        "Image": "fx_beam",
        "Grey": "fx_beam",
        "Color": c3(LINE),
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
    on = needles(6, [26, 40], [0.12, 0.2], 35, 1.0, 0)
    on["From"] = "Land"
    on["Body"] = "HumanoidRootPart"
    on["Hold"] = True
    on["Tracks"]["At"] = [[0, v3(0, 0, -0.8)]]  # from the slash, in front of the body (the content check, AR52)
    on["Why"] = "needles on along the run as it lands"
    for row in rows.values():  # the lane and the fuse stay on the stone where the line was laid
        row["Body"] = "HumanoidRootPart"
        row["Hold"] = True
    rows.update({"Streak": streak, **slash, "On": on})
    return effect("DasherLine", "The Dasher's line, DasherLunge's own effect: the grey block-in (AR52).", rows, action="DasherLunge", world=True)


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
