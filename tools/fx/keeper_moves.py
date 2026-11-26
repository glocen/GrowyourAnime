"""The Lamplighter's swing and challenge, in grey, as rows files for tools/fx/rows_take.py. Scintilla's.

    py tools/fx/keeper_moves.py [out_dir]        (default: build/handoff/Lamplighter/fx)

Both are their actions' own effects, so the rows' logic case takes them only once KeeperSwing and KeeperChallenge name
them as their Effect (Definitions.Actions): the builder takes them with that line.

KeeperSwing. Feel line: the keeper sweeps its pole round at your fighter's chest, the foot cutting a pale arc that snaps
off where it passes, the great lantern dragging a fainter one behind. Hero: the trail behind the pole's foot (PoleFoot),
from eight frames before Strike to four after, widest on Strike; a crescent cut on Strike where the foot is. The lantern's
trail is lower, softer and later: the weight swinging round after the blow.

KeeperChallenge. Feel line: the keeper hears you, lifts its face and its lantern flares, then it stamps its pole and a
ring runs out along the street from its foot. Hero: the lantern's flare on Lift (its own glow, cold 1.2 to hot 3 and back);
on Stamp a hoop flat on the street opening from the pole's foot, the paper's dust a breath after.

Written at the keeper's scale (Area 1.5, as KeeperSignature), so studs are as seen. Grey: every colour its grey.
"""
import json
import sys
from pathlib import Path

from hit_sparks import LINE, c3, sheet_rows, v3
from shade_tells import at_beat

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "handoff" / "Lamplighter" / "fx"
AREA = 1.5  # the keeper's scale (Definitions.Enemies), as KeeperSignature is written
LANTERN_COLD, LANTERN_HOT = 1.2, 3.0  # the lantern's glow (Lamplighter.recipe.json, emissive)


def trail(body, beat, keys_width, lag, why):
    return {
        "Kind": "Beam",
        "From": beat,
        "Body": body,
        "Image": "fx_beam",
        "Grey": "fx_beam",
        "Color": c3(LINE),
        "Beam": {"FaceCamera": True, "LightEmission": 1, "LightInfluence": 0, "TextureMode": "Stretch", "TextureSpeed": 0, "Segments": 1},
        "Trail": {"Back": 0, "Beyond": 0},
        "Tracks": {
            "At": [[keys_width[0][0], v3(0, 0, 0)]],
            "Width": keys_width,
            "Lag": [[keys_width[0][0], lag]],
            "Transparency": [[keys_width[0][0], 0.6, "Quad Out"], [0, 0.05, "Quad In"], [keys_width[-1][0], 1]],
        },
        "Why": why,
    }


def effect(name, why, rows, action):
    return {"Schema": "rows/1", "Effect": name, "Why": why, "Area": AREA, "Grey": True, "Action": action, "Rows": rows}


def swing():
    sweep = trail("PoleFoot", "Strike", [[-8, 0.2, "Quad In"], [0, 1.4, "Quad Out"], [4, 0]], 5,
                  "the hero: the pole's foot cutting a pale arc round to the blow, widest on Strike")
    drag = trail("Lantern", "Strike", [[-4, 0.2, "Sine InOut"], [4, 0.9, "Quad Out"], [14, 0]], 7,
                 "the lantern's weight dragged round after the blow: lower, softer, later")
    drag["Tracks"]["Transparency"] = [[-4, 0.8, "Quad Out"], [4, 0.45, "Quad In"], [14, 1]]
    cut = at_beat(sheet_rows("Cut", "crescent", 0.3, [[0, 3], [0.15, 4.4], [1, 4.8]], 0.3, 0,
                             "the cut where the pole's foot passes on Strike"), "Cut", "Strike")
    for row in cut.values():
        row["Body"] = "PoleFoot"
        row["Hold"] = True
    return effect("KeeperSwing", "The keeper's swing, KeeperSwing's own effect: the grey block-in (Scintilla).",
                  {"Sweep": sweep, "Drag": drag, **cut}, "KeeperSwing")


def challenge():
    gaze = {
        "Kind": "Glow",
        "From": "Lift",
        "Part": ["Lamplighter_Lantern"],
        "Tracks": {"Glow": [[-4, LANTERN_COLD, "Quad Out"], [3, LANTERN_HOT, "Sine InOut"], [14, LANTERN_HOT * 0.8, "Quad In"], [30, LANTERN_COLD]]},
        "Why": "the lantern flares as it lifts its face to you: it has heard you",
    }
    hoop = {
        "Kind": "Mesh",
        "From": "Stamp",
        "Body": "PoleFoot",
        "Ground": True,
        "Hold": True,
        "Part": ["FxHoop"],
        "Look": "fx_rise_Warm",
        "Grey": "fx_rise_Grey",
        "Tracks": {
            "At": [[0, v3(0, 0.03, 0)]],
            "Scale": [[0, v3(0.3, 0.6, 0.3), "Quart Out"], [18, v3(3.2, 0.25, 3.2)]],
            "Transparency": [[0, 0.1, "Quad In"], [18, 1]],
            "Glow": [[0, 2.5, "Quad Out"], [18, 1]],
        },
        "Why": "the stamp: a hoop flat on the street opening from the pole's foot, its upright band keeping it read from a low camera",
    }
    dust = at_beat(sheet_rows("Dust", "puff", 0.5, [[0, 1.6], [1, 2.8]], 0.45, 40,
                              "the street's dust off the stamp, a breath after"), "Dust", "Stamp", frame=2)
    for row in dust.values():
        row["Body"] = "PoleFoot"
        row["Hold"] = True
        row["Tracks"]["At"] = [[2, v3(0, 0.6, 0)]]
    return effect("KeeperChallenge", "The keeper's challenge, KeeperChallenge's own effect: the grey block-in (Scintilla).",
                  {"Gaze": gaze, "Hoop": hoop, **dust}, "KeeperChallenge")


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else OUT
    out.mkdir(parents=True, exist_ok=True)
    for data in (swing(), challenge()):
        path = out / f"{data['Effect']}.rows.json"
        path.write_bytes((json.dumps(data, indent=2) + "\n").encode("utf-8"))
        print(f"wrote {path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else path}")


if __name__ == "__main__":
    main()
