"""The Shades' tells (AR52, "Scintilla's looks"): the Guard's ward and the Dasher's lane, written as rows files for
tools/fx/rows_take.py. Scintilla's, the effect family's one script. Built to research's picks of 2026-11-26 (the ward
W2, after the director rejected G2's build at 12:57, "too thick", "glass"; the lane D1; their targets in
build/handoff/Shade/targets/, drawn by tools/fx/ward_targets.py and tools/fx/shade_targets.py), in their colours.

    py tools/fx/shade_tells.py [out_dir]        (default: build/handoff/Shade/fx)
    py tools/fx/rows_take.py build/handoff/Shade/fx/<Effect>.rows.json ...

GuardShield and DasherLine are their actions' own effects (Definitions.Actions' Effect on GuardRaise and DasherLunge).

The Guard. Feel line: a Guard shuts its sleeves and a curved paper shield of light snaps up before it, ribbed like a
lantern; your fighter's blows skate off it in sparks where they land, until a heavy one tears it open into paper and
light. Research's condition (AR52, its pass in the game): it reads as raised apart from the mask, never as a bigger face,
and a glance shows itself where the hit lands. At the quarter: the ribs read as paper and lantern, or it's any game's ring.
- GuardShield, GuardRaise's own effect, on its beats, riding the root: the ward (W2), a paper lantern's frame before
  the Guard's chest, lines only: five bowed ribs meeting top and bottom and two short hoops, azure light with a white
  core and a hair of deep azure ink, no surface (the vault's way: drawn lines, never glass). The target's own strokes
  as pictures, on five flat particles facing the blow, drawn toward the camera over the Guard's raised arms. It grows
  out of its middle in the eight frames before Raise, clicks on Raise, light runs up its ribs in the hold, and it
  closes over eight frames from Drop. A break ends the action, and with it the ward at once: GuardBreak takes its place.
- GuardGlance, played by the builder's hook on each glance, anchored where the blow meets the ward, its Front the way
  the blow travels: a glint where it lands and pale azure needles skating back off it toward the attacker.
- GuardBreak, played by the hook on the break, anchored at the ward's middle the same way: the ward's frame flashed
  white for two frames as it's torn (W2's break), a ring and a puff, an azure light, and six chips of light flung out
  and on along the blow, turning, gone by a third of a second.

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

# The picked targets' colours (AR52, research's picks of 2026-11-26: the ward W2, tools/fx/ward_targets.py; the lane D1, tools/fx/shade_targets.py).
AZURE = (63, 140, 255)  # the ward's light
AZURE_DEEP = (22, 60, 140)  # W2's ink, #163C8C: the hair of deep azure laid under the light, so it holds on the pale deck
AZURE_RIM = (200, 226, 255)  # a white core with the hue in it: the glance's needles
WARD = (AZURE_RIM, AZURE, AZURE_DEEP, AZURE_DEEP)  # every ward row in the ward's own colours, the glance's and the
# break's sheets too: the sparks' cream read as beige cards beside the azure frame (research's final, 2026-11-26)
WARD_EXT = 2.2  # studs from the ward's middle to its pictures' edges (tools/fx/ward_targets.py, EXT)
WARD_DRAW = 8  # frames it's drawn on before Raise, and drawn off after Drop (W2's beats)
INK_SEEN = 0.3  # the ink's Transparency through the hold
BODY_SEEN = 0.05  # the painted body's
FLASH_SEEN = 0.55  # the added light's, white-azure: 0 on Raise, its click, then this glow (the half checkpoint, 2026-11-26)
CORE_SEEN = 0.15  # the core's: 0 on Raise
WARD_LIFT = 1.2  # studs each pass is drawn toward the camera (ZOffset), its place on the screen kept: the Guard's raised
# arms reach 1.69 studs ahead of its root in the hold, past the ward's plane at 1.6, and hid its lower half (W2 draws over them)
RUN_SEEN = 0.2  # the running light's through the hold
RUN_RATE = round(16 * 60 / 70, 2)  # its sheet's 16 steps over the run's cycle of 70 frames (ward_targets.RUN_CYCLE)
AMBER = (255, 154, 31)  # the lane's light, Neon in its edges and fuse
AMBER_CORE = (255, 232, 196)  # the edges' white core
AMBER_DEEP = (122, 58, 0)  # laid under the light, so the lane holds on the pale deck
AMBER_HOT = (255, 206, 140)  # the run's streak, the landing's needles
GUARD_AT = (0, 0.7, -1.6)  # the ward's middle from the root: Config.Combat.Guard.Look's Ahead 1.6, Up 0.4, and the
# target's 0.3 more (shade_targets.draw_guard)


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
    """W2, research's pick (AR52): the lantern's frame, five bowed ribs and two hoops, lines only, no surface. Its strokes
    are pictures drawn by the target's own code (ward_targets.pictures), each one flat particle before the Guard's chest
    facing the blow (VelocityPerpendicular, held to its carrier), the vault's way for a held flat shape, so it stands in
    the Guard's own plane and the camera sees it turned as the Guard is. Its passes, under to over: the ink, a hair of
    deep azure; the body painted azure (LightEmission 0), so it reads as blue lines on the pale deck, where added light
    went white (the quarter checkpoint, 2026-11-26); the flash, the body's light added white-azure, full on Raise and
    the strokes' glow after; the run, light climbing the ribs in the hold, a looped flipbook, added; the white core,
    added. Every pass drawn WARD_LIFT toward the camera, over the Guard's raised arms (the half checkpoint). One particle
    each for the action's whole life: opened over the eight frames before Raise, its click on Raise, held, closed over
    eight frames from Drop. A break ends the action, and the ward with it: GuardBreak takes its place."""
    d = RAISE_TO_DROP
    span = d + 2 * WARD_DRAW
    life = span / 60

    def q(frame):  # a frame from Raise as a share of the particle's life
        return round((frame + WARD_DRAW) / span, 4)

    size = [[t, round(WARD_EXT * k, 3)] for t, k in ((0, 0.15), (q(-6), 0.62), (q(-4), 0.88), (q(-1), 1), (q(d), 1),
                                                       (q(d + 4), 0.8), (1, 0.1))]  # Size: half the quad, the picture's EXT

    def fade(seen, click=None, start=None):  # opened, its click on Raise (if any), held at `seen`, gone
        keys = [[0, 1 if start is None else start], [q(-1), seen]]
        if click is not None:
            keys += [[q(0), click], [q(5), seen]]
        return keys + [[q(d), seen], [1, 1]]

    def flat(picture, colour, emission, transparency, z, why, brightness=1, more=None):
        return {
            "Kind": "Emitter",
            "From": "Raise",
            "Image": picture,
            "Emitter": {
                "Lifetime": [life, life],
                "Speed": [0.01, 0.01],
                "EmissionDirection": "Front",
                "Orientation": "VelocityPerpendicular",
                "LockedToPart": True,
                "Rotation": [0, 0],
                "RotSpeed": [0, 0],
                "Size": size,
                "Transparency": transparency,
                "Color": c3(colour),
                "LightEmission": emission,
                "LightInfluence": 0,
                "Brightness": brightness,
                "ZOffset": round(WARD_LIFT + z, 3),
                **(more or {}),
            },
            "Emit": [[-WARD_DRAW, 1]],
            "Tell": True,  # a tell: drawn at every Effects level
            "Tracks": {"At": [[-WARD_DRAW, v3(*GUARD_AT)]]},
            "Why": why,
        }

    rows = {
        "Ink": flat("guard_ward_ink", AZURE_DEEP, 0, fade(INK_SEEN), 0,
                    "W2's ink: a hair of deep azure along every stroke, under the rest"),
        "Body": flat("guard_ward_light", AZURE, 0, fade(BODY_SEEN, start=0.6), 0.02,
                     "the hero: the lantern's frame, five ribs and two hoops, painted azure so it reads blue by day"),
        "Flash": flat("guard_ward_light", AZURE_RIM, 1, fade(FLASH_SEEN, click=0), 0.03,
                      "the body's light added, white-azure: full on Raise, its click, then the strokes' glow (W2's white ribs)",
                      brightness=1.5),
        "Run": flat("guard_ward_run", AZURE_RIM, 1, [[0, 1], [q(5), 1], [q(14), RUN_SEEN], [q(d), RUN_SEEN], [1, 1]], 0.035,
                    "the hold: light running up the ribs, each a little behind its neighbour (W2's run), from after the click",
                    brightness=1.5, more={"FlipbookLayout": "Grid4x4", "FlipbookMode": "Loop",
                                          "FlipbookFramerate": [RUN_RATE, RUN_RATE]}),
        "Core": flat("guard_ward_core", (255, 255, 255), 1, fade(CORE_SEEN, click=0), 0.04,
                     "the strokes' white core where they're thickest"),
    }
    ride(rows)
    return effect("GuardShield", "The Guard's raised ward, GuardRaise's own effect: research's pick, W2, the lantern's "
                  "frame (AR52).", rows, action="GuardRaise")


def guard_glance():
    rows = {
        **sheet_rows("Glint", "glint", 0.22, [[0, 1.2], [0.15, 1.8], [1, 1.6]], 0.85, 30,
                     "where the blow meets the paper: a glint, small, a glance and not a hit", colours=WARD),
        "Skate": needles(5, [18, 28], [0.1, 0.18], 75, 0.7, 0, direction="Back", colour=AZURE_RIM),
    }
    rows["Skate"]["Why"] = "the needles skating back off the shield toward the attacker: the blow turned aside"
    return effect("GuardGlance", "A blow glancing off the Guard's ward, at the hook's anchor (AR52, G2).", rows)


def guard_break():
    rows = {
        **sheet_rows("Tear", "ring", 0.32, [[0, 2.4], [1, 5]], 0.34, 0,
                     "the shield torn open: a ring out from its middle", colours=WARD),
        **sheet_rows("Puff", "puff", 0.45, [[0, 2], [1, 3.4]], 0.45, 40,
                     "the paper's dust where it was, a breath after", colours=WARD),
        "Light": {
            "Kind": "Light",
            "Range": 7,
            "Color": c3(AZURE),
            "Tracks": {"At": [[0, v3(0, 0, 0.5)]], "Brightness": [[0, 2.5, "Quad Out"], [8, 0]]},
            "Why": "the break lights the Guard for a moment",
        },
        "Snap": {
            "Kind": "Emitter",
            "Image": "guard_ward_light",
            "Emitter": {
                "Lifetime": [2 / 60, 2 / 60],
                "Speed": [0.01, 0.01],
                "EmissionDirection": "Front",
                "Orientation": "VelocityPerpendicular",
                "LockedToPart": True,
                "Rotation": [0, 0],
                "RotSpeed": [0, 0],
                "Size": [[0, WARD_EXT], [1, round(WARD_EXT * 1.06, 3)]],
                "Transparency": [[0, 0], [1, 0.4]],
                "Color": c3((255, 255, 255)),
                "LightEmission": 1,
                "LightInfluence": 0,
                "Brightness": 3,
                "ZOffset": round(WARD_LIFT + 0.05, 3),
            },
            "Emit": [[0, 1]],
            "Tracks": {"At": [[0, v3(0, 0, 0)]]},
            "Why": "W2's break: the ward's frame flashes white for two frames as it's torn, then it's gone",
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
