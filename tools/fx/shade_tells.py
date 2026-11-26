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

The elites' moves (TR69 B; research's picks of 2026-11-26, from the targets in build/handoff/Fight/targets/elite/,
drawn by tools/fx/elite_tell_targets.py, which also draws their pictures with --pictures). Feel line (research, 22:05): from
the player's camera, each elite's one move announces itself a beat before it lands, so the player knows which elite it is
and when to step away. Each is its action's own effect, written at its elite's size (Area, the elite's Scale in
Definitions.Enemies), so at that scale nothing is scaled, and the floor stays on the street.
- ShadeOverhead, the Brawler elite's overhead (O2): a ring round its mask closes at a steady rate through the 1.2 s
  wind-up, from 1.85 times its end to tight on the mask, heating from amber to white, and the footprint where the blow
  lands lies on the street in D1's make, its fill growing to the strike, its rim heating. On Strike both flash white
  together and the ring is gone; needles of light leap off the footprint. No ticks, no crosshair: a countdown, never a
  lock-on (research's must-fix). The ring rides the mask; the footprint is held where it was laid on the first frame.
- DasherFan, the Dasher elite's fan (F1): DasherLine's lane three times, the middle at its target and the others 25
  degrees either side (research, 22:15), drawn at once, only the outline of the three together stroked, so the notches
  between the lanes show the gaps; each lane's fuse lit in turn to Land, the rim heating. The Dasher runs the middle;
  a streak of light runs each side lane in the same quarter second, and a slash bursts at each lane's end.
- GuardScreen, the Guard elite's screen (S1): the ward's way, at the wall's size: a lantern wall 8 studs across, nine
  ribs and two rails, W2's lines only, on GuardRaise's beats. Its glance is GuardGlance. Its break, GuardScreenBreak,
  is GuardBreak's at the wall's size, anchored at the Guard's root: the tear from the wall's middle, and the whole
  wall's frame flashed white with nine chips flung off it.

Frames at 60 a second from each row's beat. The colours passed their content check on 2026-11-26 (AR52): nothing red,
the chips light, never dark or liquid, nothing left behind (AGENTS.md, rule 4).
"""
import json
import math
import re
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
    rows = ward_rows("guard_ward", WARD_EXT, GUARD_AT, lift=WARD_LIFT,
                     what="the hero: the lantern's frame, five ribs and two hoops, painted azure so it reads blue by day")
    return effect("GuardShield", "The Guard's raised ward, GuardRaise's own effect: research's pick, W2, the lantern's "
                  "frame (AR52).", rows, action="GuardRaise")


def ward_rows(picture, ext, at, lift, what):
    """W2's passes on one set of pictures (picture + _ink, _light, _run, _core), `ext` studs from their middle to their
    edge, at `at` from the root, drawn `lift` studs toward the camera: the ward's (guard_shield) and the screen's."""
    d = RAISE_TO_DROP
    span = d + 2 * WARD_DRAW
    life = span / 60

    def q(frame):  # a frame from Raise as a share of the particle's life
        return round((frame + WARD_DRAW) / span, 4)

    size = [[t, round(ext * k, 3)] for t, k in ((0, 0.15), (q(-6), 0.62), (q(-4), 0.88), (q(-1), 1), (q(d), 1),
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
                "ZOffset": round(lift + z, 3),
                **(more or {}),
            },
            "Emit": [[-WARD_DRAW, 1]],
            "Tell": True,  # a tell: drawn at every Effects level
            "Tracks": {"At": [[-WARD_DRAW, v3(*at)]]},
            "Why": why,
        }

    rows = {
        "Ink": flat(f"{picture}_ink", AZURE_DEEP, 0, fade(INK_SEEN), 0,
                    "W2's ink: a hair of deep azure along every stroke, under the rest"),
        "Body": flat(f"{picture}_light", AZURE, 0, fade(BODY_SEEN, start=0.6), 0.02, what),
        "Flash": flat(f"{picture}_light", AZURE_RIM, 1, fade(FLASH_SEEN, click=0), 0.03,
                      "the body's light added, white-azure: full on Raise, its click, then the strokes' glow (W2's white ribs)",
                      brightness=1.5),
        "Run": flat(f"{picture}_run", AZURE_RIM, 1, [[0, 1], [q(5), 1], [q(14), RUN_SEEN], [q(d), RUN_SEEN], [1, 1]], 0.035,
                    "the hold: light running up the ribs, each a little behind its neighbour (W2's run), from after the click",
                    brightness=1.5, more={"FlipbookLayout": "Grid4x4", "FlipbookMode": "Loop",
                                          "FlipbookFramerate": [RUN_RATE, RUN_RATE]}),
        "Core": flat(f"{picture}_core", (255, 255, 255), 1, fade(CORE_SEEN, click=0), 0.04,
                     "the strokes' white core where they're thickest"),
    }
    return ride(rows)


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


# --- the elites' moves (TR69 B) -----------------------------------------------------------------------------------------
WHITE_HOT = (255, 246, 232)  # the strike's white, a hair warm
OVERHEAD_WIND = 72  # frames from the overhead's first to its Strike: the 1.2 s wind-up (TR69 B)
OVERHEAD_PRINT = {"Radius": 3.0, "Ahead": 3.4}  # the blow's disc on the street, in studs, its middle ahead of the
# Brawler's root: seeds, and the hit takes the same disc
MASK_FRONT = 0.95  # studs before the mask's middle at Scale 1 where the ring stands, over the face: the mask is 1.75 deep
FAN_SPREAD = 25  # degrees between the fan's lanes (research, 22:15)
SCREEN_AHEAD = 2.6  # studs before the Guard elite's root, past its raised arms (2.28 at its size)


def elite_scale(kind):
    """An elite's Scale, from its row in Definitions.Enemies, so the rows follow a retune when the script runs again."""
    text = (ROOT / "src" / "shared" / "Definitions" / "Enemies.luau").read_text(encoding="utf-8")
    return float(re.search(r'Id = "%s_elite"[^\n]*?Scale = ([\d.]+)' % kind, text).group(1))


def heat(n, hot=AMBER_HOT):
    """A rim's colour to the hit on frame n: amber, warming over the last 24 frames."""
    return [[0, c3(AMBER), "Linear"], [n - 24, c3(AMBER), "Quad In"], [n, c3(hot)]]


def shade_overhead():
    from elite_tell_targets import HALO
    k = elite_scale("brawler")
    w = OVERHEAD_WIND
    radius, ahead = OVERHEAD_PRINT["Radius"], OVERHEAD_PRINT["Ahead"]
    floor = -ROOT_HEIGHT * k + 0.04

    def card(r):  # the ring's card across, at the elite's size, for a radius r at Scale 1
        return round(2 * r * k / HALO["Share"], 3)

    size = [[-w, card(HALO["Start"]), "Linear"], [0, card(HALO["End"]), "Quad Out"], [5, card(HALO["End"] * 1.2)]]
    front = -MASK_FRONT * k

    def ring(name, picture, z, why, **tracks):
        return {"Kind": "Card", "From": "Strike", "Body": "Mask_Brawler", "Image": picture, "Tracks": {
            "At": [[-w, v3(0, 0, round(front - z, 3))]], "Size": size, **tracks}, "Why": why}

    rows = {
        "RingInk": {**ring("RingInk", "overhead_ring_ink", 0, "the ring's hair of warm ink, under it, so it holds on a "
                            "lit stall front", Transparency=[[-w, 1, "Quad Out"], [-w + 4, 0.35, "Linear"], [0, 0.35, "Linear"], [2, 1]]),
                    "Color": c3((42, 20, 0))},
        "Ring": {**ring("Ring", "overhead_ring_light", 0.02, "the countdown: a ring round the mask closing at a steady "
                        "rate, amber, heating to white as the strike nears, flashing white on it and gone",
                        Transparency=[[-w, 1, "Quad Out"], [-w + 4, 0, "Linear"], [2, 0, "Quad In"], [5, 1]],
                        Color=[[-w, c3(AMBER), "Linear"], [-24, c3(AMBER), "Quad In"], [-4, c3(AMBER_HOT), "Linear"], [0, c3(WHITE_HOT)]],
                        Brightness=[[-w, 1, "Linear"], [-24, 1, "Quad In"], [0, 2.5]]),
                 "Color": c3(AMBER)},
        "RingCore": {**ring("RingCore", "overhead_ring_core", 0.04, "its white core, faint at first and full on the strike",
                            Transparency=[[-w, 1, "Quad Out"], [-w + 4, 0.7, "Linear"], [-24, 0.6, "Quad In"], [0, 0],
                                          [2, 0, "Quad In"], [5, 1]]),
                     "Color": c3((255, 255, 255))},
        "RingLight": {"Kind": "Light", "From": "Strike", "Body": "Mask_Brawler", "Color": c3(AMBER), "Range": round(6 * k, 2),
                      "Tracks": {"At": [[-w, v3(0, 0, round(front - 0.4, 3))]],
                                 "Brightness": [[-w, 0, "Linear"], [-24, 0.4, "Quad In"], [0, 3], [2, 3, "Quad In"], [8, 0]]},
                      "Why": "light round the mask, rising to the strike: never a tint on the face"},
    }
    # the footprint, D1's make on a disc: laid faint, its fill growing from the middle to the strike (linear, the honest
    # timer), its rim a ring of strokes heating to the strike; all of it white on Strike and closed over six frames
    centre = -ahead
    laid = {"Look": "fx_rise_Grey", "Grey": "fx_rise_Grey", "Color": c3(AMBER_DEEP)}
    shut = [[2, 0, "Quad In"], [8, 1]]
    rows["Field"] = {"Kind": "Mesh", "From": "Strike", "Part": ["FxShell"], **laid, "Tracks": {
        "At": [[-w, v3(0, round(floor - 0.01, 3), centre)]],
        "Scale": [[-w, v3(0.1, 0.02, 0.1), "Back Out"], [-w + 5, v3(radius, 0.02, radius)]],
        "Transparency": [[-w, 0.8, "Linear"], [2, 0.8, "Quad In"], [8, 1]], "Glow": [[-w, 2.5, "Quad Out"], [-w + 5, 1.5]]},
        "Why": "the footprint laid: a faint amber disc on the street, as wide as what the blow takes"}
    rows["Fill"] = {"Kind": "Mesh", "From": "Strike", "Part": ["FxShell"], "Color": c3(AMBER), "Tracks": {
        "At": [[-w, v3(0, round(floor, 3), centre)]],
        "Scale": [[-w, v3(0.05, 0.02, 0.05), "Linear"], [0, v3(radius, 0.02, radius)]],
        "Color": [[-w, c3(AMBER), "Linear"], [-8, c3(AMBER), "Linear"], [0, c3(WHITE_HOT)], [2, c3(WHITE_HOT), "Linear"], [8, c3(AMBER_HOT)]],
        "Transparency": [[-w, 0.62, "Linear"], [-1, 0.5, "Linear"], [0, 0.1], *shut]},
        "Why": "the fill, growing from the middle to the rim on the strike: the time left to move; white on the strike"}
    count, width, core = 16, 0.16, 0.05
    chord = 2 * radius * math.sin(math.pi / count)
    mid = radius * math.cos(math.pi / count)
    for i in range(count):
        a = 2 * math.pi * (i + 0.5) / count
        for suffix, wide, lift, colour in (("", width, 0.04, None), ("Core", core, 0.05, AMBER_CORE)):
            rows[f"Rim{i + 1:02d}{suffix}"] = {"Kind": "Mesh", "From": "Strike", "Part": ["FxPlate"],
                                               "Color": c3(colour or AMBER), "Tracks": {
                "At": [[-w, v3(round(mid * math.cos(a), 4), round(floor + lift, 3), round(centre + mid * math.sin(a), 4))]],
                "Spin": [[-w, round(-math.degrees(a), 3)]],
                "Scale": [[-w, v3(0.02, 0.02, round(chord + width / 2, 4)), "Back Out"], [-w + 5, v3(wide, 0.02, round(chord + width / 2, 4)), "Linear"],
                          [2, v3(wide, 0.02, round(chord + width / 2, 4)), "Quad In"], [8, v3(0.02, 0.02, round(chord + width / 2, 4))]],
                **({"Color": [[c[0] - w, *c[1:]] for c in heat(w, WHITE_HOT)]} if not suffix else {}),
                "Transparency": [[-w, 0, "Linear"], [2, 0.1, "Quad In"], [8, 1]]},
                "Why": f"the footprint's rim, stroke {i + 1} of {count}: where the blow's reach ends, heating to the strike"
                + (": its white core" if suffix else "")}
    spray = needles(10, [30, 46], [0.14, 0.22], 70, 1.3, 0, direction="Top", colour=AMBER_HOT)
    spray.update({"From": "Strike", "Tell": True,
                  "Why": "needles of light leaping off the footprint on the strike: never falling, never liquid"})
    spray["Tracks"]["At"] = [[-w, v3(0, round(floor + 0.2, 3), centre)]]  # laid with the footprint
    rows["Spray"] = spray
    rows["Flash"] = {"Kind": "Light", "From": "Strike", "Color": c3(AMBER_HOT), "Range": 10, "Tracks": {
        "At": [[-w, v3(0, round(floor + 1.2, 3), centre)]],
        "Brightness": [[-w, 0, "Linear"], [-1, 0, "Linear"], [0, 4, "Quad In"], [8, 0]]},
        "Why": "the strike's light on the street and the bodies"}
    for name, row in rows.items():
        if not name.startswith("Ring"):  # the footprint stays on the stone where it was laid
            row["Body"] = "HumanoidRootPart"
            row["Hold"] = True
    data = effect("ShadeOverhead", "The Brawler elite's overhead, its action's own effect: research's pick, O2, the ring "
                  "round the mask, with the footprint in D1's make (TR69 B).", rows, action="ShadeOverhead")
    data["Area"] = k
    return data


def lane_outline(spread, half, length, step=0.05):
    """The fan's three lanes as one shape: of each lane's stadium edge (its two sides, a half circle round each end),
    the runs outside the other two. Returns strokes: (kind, lane angle in degrees, local points) for a side, or
    (kind, lane angle, start and end angles) for an end's arc; local is the lane's own frame, x across, z along -z."""
    angles = (spread, 0, -spread)

    def rot(x, z, deg):
        t = math.radians(deg)
        return x * math.cos(t) + z * math.sin(t), -x * math.sin(t) + z * math.cos(t)

    def outside(x, z, skip):
        for j, deg in enumerate(angles):
            if j == skip:
                continue
            lx, lz = rot(x, z, -deg)  # into lane j's frame
            along = min(max(-lz, 0), length)
            if math.hypot(lx, -lz - along) < half - 1e-6:
                return False
        return True

    strokes = []
    for i, deg in enumerate(angles):
        for side in (-1, 1):  # the two sides, straight
            run = []
            zs = [-(t * step) for t in range(int(length / step) + 1)]
            for z in zs + [None]:
                ok = z is not None and outside(*rot(side * half, z, deg), i)
                if ok:
                    run.append(z)
                elif run:
                    if run[0] - run[-1] > 0.3:
                        strokes.append(("side", deg, (side * half, run[0], run[-1])))
                    run = []
        for end, z0, sign in (("far", -length, -1), ("near", 0, 1)):  # the ends' half circles, from the right side round
            run = []
            n = int(math.pi * half / step)
            for t in range(n + 2):
                a = math.pi * t / n if t <= n else None
                ok = a is not None and outside(*rot(half * math.cos(a), z0 + sign * half * math.sin(a), deg), i)
                if ok:
                    run.append(a)
                elif run:
                    if run[-1] - run[0] > 0.1:
                        strokes.append((end, deg, (run[0], run[-1])))
                    run = []
    return strokes


def dasher_fan():
    """F1: DasherLine's lane three times, only the outline of the three together stroked (lane_outline), each lane's
    fill laid and its fuse lit in turn to Land. The middle lane is the Dasher's own run (its streak and slash, as
    DasherLine's); the side lanes are run by a streak of light in the same quarter second, flown down each from where
    the line was laid (an emitter turned along it, so it never depends on where the Dasher stops), and slash at their
    ends from points laid at Line. Written at the elite's size, so its floor is the street at Area."""
    k = elite_scale("dasher")
    n = LINE_TO_LAND
    lunge = round((1.0 - 0.2667) * 60)  # frames from Line to Lunge: 44
    run = n - lunge
    floor = -ROOT_HEIGHT * k + 0.04
    laid = {"Look": "fx_rise_Grey", "Grey": "fx_rise_Grey", "Color": c3(AMBER_DEEP)}
    angles = (FAN_SPREAD, 0, -FAN_SPREAD)

    def rot(x, z, deg):
        t = math.radians(deg)
        return round(x * math.cos(t) + z * math.sin(t), 4), round(-x * math.sin(t) + z * math.cos(t), 4)

    def open_close(wide, deep, long):
        return [[0, v3(0.02, deep, long), "Back Out"], [4, v3(wide, deep, long), "Linear"], [n, v3(wide, deep, long), "Quad In"],
                [n + 6, v3(0.02, deep, long)]]
    rows = {"LaneNear": {"Kind": "Mesh", "From": "Line", "Part": ["FxShell"], **laid, "Tracks": {
        "At": [[0, v3(0, round(floor - 0.01, 3), 0)]], "Scale": open_close(LINE_HALF, 0.02, LINE_HALF),
        "Transparency": [[0, 0.86, "Linear"], [n, 0.88, "Quad In"], [n + 6, 1]], "Glow": [[0, 2.5, "Quad Out"], [4, 1.5]]},
        "Why": "the lanes' shared round end behind the feet, laid"}}
    steps, lit_at = 6, 0.35
    piece = LINE_LENGTH / steps
    for i, deg in enumerate(angles):
        tag = ("Left", "Mid", "Right")[i]
        x, z = rot(0, -LINE_LENGTH / 2, deg)
        rows[f"Lane{tag}"] = {"Kind": "Mesh", "From": "Line", "Part": ["FxPlate"], **laid, "Tracks": {
            "At": [[0, v3(x, floor, z)]], "Spin": [[0, deg]], "Scale": open_close(2 * LINE_HALF, 0.04, LINE_LENGTH),
            "Transparency": [[0, 0.8, "Linear"], [n, 0.82, "Quad In"], [n + 6, 1]], "Glow": [[0, 2.5, "Quad Out"], [4, 1.5]]},
            "Why": f"the {tag.lower()} lane, laid: faint, so the lanes' overlap by the feet stays near one's own"}
        x, z = rot(0, -LINE_LENGTH, deg)
        rows[f"Lane{tag}Far"] = {"Kind": "Mesh", "From": "Line", "Part": ["FxShell"], **laid, "Tracks": {
            "At": [[0, v3(x, round(floor - 0.01, 3), z)]], "Scale": open_close(LINE_HALF, 0.02, LINE_HALF),
            "Transparency": [[0, 0.84, "Linear"], [n, 0.86, "Quad In"], [n + 6, 1]], "Glow": [[0, 2.5, "Quad Out"], [4, 1.5]]},
            "Why": f"the {tag.lower()} lane's far round end, laid"}
        for s_ in range(1, steps + 1):
            lit, full = round(n * (s_ - 1) / steps), round(n * s_ / steps)
            x, z = rot(0, -(s_ - 0.5) * piece, deg)
            rows[f"Fuse{tag}{s_}"] = {"Kind": "Mesh", "From": "Line", "Part": ["FxPlate"], "Color": c3(AMBER), "Tracks": {
                "At": [[0, v3(x, round(floor + 0.02, 3), z)]], "Spin": [[0, deg]],
                "Scale": open_close(LINE_HALF * 1.6, 0.02, piece),
                "Transparency": ([[0, 1, "Linear"]] if lit > 0 else []) + [[lit, 1, "Quad Out"]]
                + ([[full, lit_at, "Linear"]] if full < n else []) + [[n, lit_at, "Quad In"], [n + 6, 1]]},
                "Why": f"the {tag.lower()} lane's fuse, piece {s_} of {steps}: lit in turn from the feet, whole on Land"}
    width, core = 0.16, 0.05
    edge = 0
    for kind, deg, span in lane_outline(FAN_SPREAD, LINE_HALF, LINE_LENGTH):
        if kind == "side":
            sx, z0, z1 = span
            pieces = [(sx, (z0 + z1) / 2, abs(z0 - z1) + width / 2, 0)]
        else:
            a0, a1 = span
            parts = max(1, math.ceil((a1 - a0) / (math.pi / 6)))
            pieces = []
            for j in range(parts):
                b0, b1 = a0 + (a1 - a0) * j / parts, a0 + (a1 - a0) * (j + 1) / parts
                am, half_span = (b0 + b1) / 2, (b1 - b0) / 2
                m = LINE_HALF * math.cos(half_span)
                if kind == "far":
                    pieces.append((m * math.cos(am), -LINE_LENGTH - m * math.sin(am), 2 * LINE_HALF * math.sin(half_span) + width / 2, math.degrees(am)))
                else:
                    pieces.append((m * math.cos(am), m * math.sin(am), 2 * LINE_HALF * math.sin(half_span) + width / 2, -math.degrees(am)))
        for lx, lz, long, spin in pieces:
            edge += 1
            x, z = rot(lx, lz, deg)
            for suffix, wide, lift, colour in (("", width, 0.04, AMBER), ("Core", core, 0.05, AMBER_CORE)):
                rows[f"Edge{edge:02d}{suffix}"] = {"Kind": "Mesh", "From": "Line", "Part": ["FxPlate"], "Color": c3(colour), "Tracks": {
                    "At": [[0, v3(x, round(floor + lift, 3), z)]], "Spin": [[0, round(spin + deg, 3)]],
                    "Scale": open_close(wide, 0.02, round(long, 4)),
                    **({"Color": heat(n)} if not suffix else {}),
                    "Transparency": [[0, 0, "Linear"], [n, 0.1, "Quad In"], [n + 6, 1]]},
                    "Why": "the fan's outline, the three lanes as one: where the hit's reach ends, heating to Land"
                    + (": its white core" if suffix else "")}
    rows["Streak"] = {
        "Kind": "Beam", "From": "Lunge", "Body": "HumanoidRootPart", "Image": "fx_beam", "Grey": "fx_beam", "Color": c3(AMBER_HOT),
        "Beam": {"FaceCamera": True, "LightEmission": 1, "LightInfluence": 0, "TextureMode": "Stretch", "TextureSpeed": 0, "Segments": 1},
        "Trail": {"Back": round(0.3 * k, 3), "Beyond": 0},
        "Tracks": {"At": [[0, v3(0, round(-0.6 * k, 3), 0)]], "Width": [[0, round(1.2 * k, 3), "Linear"], [15, round(1.2 * k, 3), "Quad In"], [24, 0]],
                   "Lag": [[0, 6]], "Transparency": [[0, 0.1, "Quad In"], [24, 1]]},
        "Why": "the run: a streak behind the Dasher down the middle lane"}
    slash_at = LINE_LENGTH - LINE_HALF + 0.8  # where a run ends and its slash bursts, before the lane's far end
    for i, deg in enumerate(angles):
        tag = ("Left", "Mid", "Right")[i]
        x, z = rot(0, -slash_at, deg)
        rows[f"End{tag}"] = {"Kind": "Point", "From": "Line", "Body": "HumanoidRootPart", "Hold": True,
                             "Tracks": {"At": [[0, v3(x, round(floor + 1.2 * k, 3), z)]], "Spin": [[0, deg]]},
                             "Why": f"where the {tag.lower()} run ends, laid at Line"}
        slash = at_beat(sheet_rows(f"Slash{tag}", "crescent", 0.3, [[0, 3 * k], [0.15, 4.2 * k], [1, 4.6 * k]], 0.3, 0,
                                   f"where the {tag.lower()} run lands: the crescent sheet across it"), f"Slash{tag}", "Land")
        for row in slash.values():
            row["On"] = f"End{tag}"
            row["Tracks"]["At"] = [[0, v3(0, 0, 0)]]
        rows.update(slash)
        if deg:
            x, z = rot(0, 0, deg)
            rows[f"Run{tag}Start"] = {"Kind": "Point", "From": "Line", "Body": "HumanoidRootPart", "Hold": True,
                                      "Tracks": {"At": [[0, v3(0, round(-0.6 * k, 3), 0)]], "Spin": [[0, deg]]},
                                      "Why": f"the {tag.lower()} lane's start, laid at Line, turned down it"}
            flown = needles(3, [44, 48], [0.26, 0.27], 2, round(2.6 * k, 2), 0, colour=AMBER_HOT)
            flown["Emitter"]["Drag"] = 0
            flown.update({"From": "Lunge", "On": f"Run{tag}Start", "Tell": True,
                          "Why": f"the {tag.lower()} lane run in the same quarter second: streaks of light flown down it"})
            flown["Tracks"]["At"] = [[0, v3(0, 0, 0)]]
            rows[f"Run{tag}"] = flown
    for name, row in rows.items():
        if row.get("On") is None and not name.startswith("End") and not name.startswith("Run") and name != "Streak":
            row["Body"] = "HumanoidRootPart"  # the lanes stay on the stone where the line was laid
            row["Hold"] = True
    data = effect("DasherFan", "The Dasher elite's fan, its action's own effect: research's pick, F1, three lanes as one "
                  "(TR69 B).", rows, action="DasherFan")
    data["Area"] = k
    return data


def guard_screen():
    """S1, the lantern wall: the ward's own passes (ward_rows) on the screen's pictures, at the wall's size."""
    from elite_tell_targets import SCREEN_EXT, SCREEN_MID
    k = elite_scale("guard")
    rows = ward_rows("guard_screen", SCREEN_EXT, (0, round(-ROOT_HEIGHT * k + SCREEN_MID, 3), -SCREEN_AHEAD), lift=0.4,
                     what="the lantern wall, nine ribs and two rails, painted azure so it reads blue by day")
    data = effect("GuardScreen", "The Guard elite's screen, its action's own effect: research's pick, S1, the lantern "
                  "wall (TR69 B).", rows, action="GuardScreen")
    data["Area"] = k
    return data


def guard_screen_break():
    """The screen broken (TR69 B), GuardBreak's way at the wall's size, all of it on the wall. The hook anchors it at the
    Guard's root, Front the way the Guard faces (an effect played at a point rides no body), and the rows find the wall
    from there as GuardScreen does: GuardBreak's tear, puff and light from the wall's middle, at the elite's size; the
    whole wall's frame flashed white for two frames as it's torn (W2's break); nine chips flung off across it and on
    along the blow (+Z, toward the Guard), turning, gone by a third of a second."""
    from elite_tell_targets import SCREEN_EXT, SCREEN_MID
    k = elite_scale("guard")
    wy, wz = round(-ROOT_HEIGHT * k + SCREEN_MID, 3), -SCREEN_AHEAD  # the wall's middle from the root

    def big(keys):
        return [[t, round(s * k, 3)] for t, s in keys]

    rows = {
        **sheet_rows("Tear", "ring", 0.32, big([[0, 2.4], [1, 5]]), 0.34, 0,
                     "the wall torn open: a ring out from its middle", colours=WARD),
        **sheet_rows("Puff", "puff", 0.45, big([[0, 2], [1, 3.4]]), 0.45, 40,
                     "the paper's dust where it stood, a breath after", colours=WARD),
        "Light": {
            "Kind": "Light",
            "Range": round(7 * k, 2),
            "Color": c3(AZURE),
            "Tracks": {"At": [[0, v3(0, wy, round(wz - 0.5 * k, 3))]], "Brightness": [[0, 2.5, "Quad Out"], [8, 0]]},
            "Why": "the break lights the Guard and the wall for a moment",
        },
        "Snap": {
            "Kind": "Emitter",
            "Image": "guard_screen_light",
            "Emitter": {
                "Lifetime": [2 / 60, 2 / 60],
                "Speed": [0.01, 0.01],
                "EmissionDirection": "Front",
                "Orientation": "VelocityPerpendicular",
                "LockedToPart": True,
                "Rotation": [0, 0],
                "RotSpeed": [0, 0],
                "Size": [[0, SCREEN_EXT], [1, round(SCREEN_EXT * 1.06, 3)]],
                "Transparency": [[0, 0], [1, 0.4]],
                "Color": c3((255, 255, 255)),
                "LightEmission": 1,
                "LightInfluence": 0,
                "Brightness": 3,
                "ZOffset": 0.45,
            },
            "Emit": [[0, 1]],
            "Tracks": {"At": [[0, v3(0, wy, wz)]]},
            "Why": "W2's break on the wall: its whole frame flashes white for two frames as it's torn, then it's gone",
        },
    }
    for key in ("TearLine", "TearFill", "TearDark"):
        rows[key]["Tracks"] = {"At": [[0, v3(0, wy, wz)]]}
    for key in ("PuffLine", "PuffFill", "PuffDark"):
        rows[key]["Emit"] = [[2, 1]]
        rows[key]["Tracks"] = {"At": [[2, v3(0, wy, wz)]]}
    # nine chips of the wall, from across it (8 wide, 3.4 high about its middle), flung out and on along the blow (+Z
    # from the wall, toward the Guard behind it), turning, gone by 20 frames
    outs = [(-3.3, 0.9), (-2.4, -0.7), (-1.5, 1.3), (-0.6, -1.1), (0.4, 1.0), (1.3, -0.5), (2.2, 1.2), (3.1, -0.9),
            (0.0, 0.2)]
    for index, (x, y) in enumerate(outs, start=1):
        rows[f"Chip{index}"] = {
            "Kind": "Mesh",
            "Part": [f"FxChip{(index - 1) % 3 + 1}"],
            "Color": c3(AZURE_RIM if index % 2 else AZURE),
            "Tracks": {
                "At": [[0, v3(round(x * 0.7, 3), round(wy + y * 0.7, 3), wz), "Quad Out"],
                       [16, v3(round(x * 1.15, 3), round(wy + y - 0.8, 3), round(wz + 1.0 + index * 0.1, 3))]],
                "Scale": [[0, round(0.9 * k, 3), "Linear"], [20, round(0.5 * k, 3)]],
                "Spin": [[0, index * 40, "Quad Out"], [20, index * 40 + (220 if index % 2 else -220)]],
                "Tilt": [[0, v3(index * 25, 0, 0), "Quad Out"], [20, v3(index * 25 + 160, 0, 90)]],
                "Transparency": [[0, 0, "Quad In"], [12, 0.1, "Quad In"], [20, 1]],
            },
            "Why": "a chip of the wall, light and paper, flung off it and on along the blow, turning",
        }
    data = effect("GuardScreenBreak", "The Guard elite's screen broken, on the wall, from the hook's anchor at the "
                  "Guard's root (TR69 B; GuardBreak's way, W2's break).", rows)
    data["Area"] = k
    return data


def build():
    return {e["Effect"]: e for e in (guard_shield(), guard_glance(), guard_break(), dasher_line(), shade_overhead(),
                                     dasher_fan(), guard_screen(), guard_screen_break())}


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else OUT
    out.mkdir(parents=True, exist_ok=True)
    for name, data in build().items():
        path = out / f"{name}.rows.json"
        path.write_bytes((json.dumps(data, indent=2) + "\n").encode("utf-8"))  # LF, as the repo keeps it
        print(f"wrote {path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else path}")


if __name__ == "__main__":
    main()
