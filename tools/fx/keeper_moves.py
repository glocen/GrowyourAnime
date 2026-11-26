"""The Lamplighter's swing and challenge, in grey, as rows files for tools/fx/rows_take.py. Scintilla's.

    py tools/fx/keeper_moves.py [out_dir]        (default: build/handoff/Lamplighter/fx)

Both are their actions' own effects, so the rows' logic case takes them only once KeeperSwing and KeeperChallenge name
them as their Effect (Definitions.Actions): the builder takes them with that line.

KeeperSwing. Feel line: the keeper sweeps its pole round at your fighter's chest, the foot cutting a pale arc that snaps
off where it passes, the great lantern dragging a fainter one behind. Hero: the trail behind the pole's foot (PoleFoot),
from eight frames before Strike to four after, widest on Strike; a crescent cut on Strike where the foot is. The lantern's
trail is lower, softer and later: the weight swinging round after the blow.

KeeperChallenge. Feel line: the keeper hears you, lifts its face and its lantern flares, then it stamps its pole and a
ring runs out along the street from its foot. Built to research's pick, C4 (AR7, "C4: picked, for the build"): the
lantern's flare on Lift (its own glow, cold 1.2 to hot 3) and a jolt brighter on Stamp; on Stamp the hero, a band of
warm light running out over the street from the pole's foot to ten studs, a fainter one a breath behind, the deep warm
laid under it and a faint fill inside. The ring is two flipbooks drawn from C4's own numbers (tools/fx/keeper_targets.py
--pictures), played once by flat particles lying on the street: the field twice, laid deep warm under and added warm
over, always together on one life (the content check's condition), and the line.

Written at the keeper's scale (Area 1.5, as KeeperSignature), so studs are as seen; a particle's size isn't scaled by
the play, so the ring stays ten studs whatever the keeper's scale. KeeperSwing is grey: every colour its grey.
"""
import json
import sys
from pathlib import Path

from hit_sparks import LINE, c3, sheet_rows, v3
from shade_tells import at_beat
from keeper_targets import RING_EXT, RING_LIFE

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


def effect(name, why, rows, action, grey=True):
    return {"Schema": "rows/1", "Effect": name, "Why": why, "Area": AREA, "Grey": grey, "Action": action, "Rows": rows}


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
    stamp = 14  # Stamp, in frames from Lift (Definitions.Actions: Lift 0.7333, Stamp 0.9667)
    gaze = {
        "Kind": "Glow",
        "From": "Lift",
        "Part": ["Lamplighter_Lantern"],
        "Tracks": {"Glow": [[-4, LANTERN_COLD, "Quad Out"], [3, LANTERN_HOT, "Sine InOut"], [stamp, LANTERN_HOT * 0.85, "Quad Out"],
                            [stamp + 1, LANTERN_HOT * 1.3, "Quad Out"], [stamp + 5, LANTERN_HOT * 0.8, "Quad In"], [30, LANTERN_COLD]]},
        "Why": "the lantern flares as it lifts its face to you, it has heard you, and jolts brighter with the stamp",
    }
    life = round(RING_LIFE / 60, 4)

    def ring(picture, colour, emission, seen, brightness, z, why):
        return {
            "Kind": "Emitter",
            "From": "Stamp",
            "Body": "PoleFoot",
            "Ground": True,
            "Hold": True,
            "Image": picture,
            "Grey": "",
            "Emitter": {
                "Lifetime": [life, life],
                "Speed": [0.01, 0.01],
                "EmissionDirection": "Top",
                "Orientation": "VelocityPerpendicular",  # flat on the street, facing up
                "LockedToPart": False,
                "Rotation": [0, 0],
                "RotSpeed": [0, 0],
                "Size": [[0, RING_EXT], [1, RING_EXT]],  # half the quad: the picture's edge RING_EXT from the foot
                "Transparency": [[0, 1 - seen], [1, 1 - seen]],
                "Color": c3(colour),
                "LightEmission": emission,
                "LightInfluence": 0,
                "Brightness": brightness,
                "ZOffset": z,  # toward the camera, off the street it lies on
                "FlipbookLayout": "Grid4x4",
                "FlipbookMode": "OneShot",  # its 16 cells once over the ring's life
            },
            "Emit": [[0, 1]],
            "Tracks": {"At": [[0, v3(0, 0, 0)]]},
            "Why": why,
        }

    rows = {
        "Gaze": gaze,
        "RingDeep": ring("keeper_ring_field", (0x7A, 0x4A, 0x12), 0, 0.4, 1, 0.3,
                         "C4's deep warm laid under the band, so the ring holds on the pale street: only ever with its light"),
        "RingWarm": ring("keeper_ring_field", (0xFF, 0xC9, 0x8A), 1, 1, 1.6, 0.32,
                         "the hero: the band of warm light running out from the pole's foot to ten studs, its twin behind"),
        "RingLine": ring("keeper_ring_line", (0xFF, 0xF6, 0xE8), 1, 1, 1.6, 0.34,
                         "the band's outer edge, a warm white line, so the ring reads all the way round"),
    }
    return effect("KeeperChallenge", "The keeper's challenge, KeeperChallenge's own effect: research's pick C4 (Scintilla).",
                  rows, "KeeperChallenge", grey=False)


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else OUT
    out.mkdir(parents=True, exist_ok=True)
    for data in (swing(), challenge()):
        path = out / f"{data['Effect']}.rows.json"
        path.write_bytes((json.dumps(data, indent=2) + "\n").encode("utf-8"))
        print(f"wrote {path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else path}")


if __name__ == "__main__":
    main()
