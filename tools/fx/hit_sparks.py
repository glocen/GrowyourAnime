"""The hit sparks (AR61, docs/asset-requests.md): the shared kit's landed-hit look, one rows effect per rung, written as
rows files for tools/fx/rows_take.py. Scintilla's, the effect family's one script.

    py tools/fx/hit_sparks.py [out_dir]        (default: build/handoff/Hits/fx)
    py tools/fx/rows_take.py build/handoff/Hits/fx/HitSpark2.rows.json build/handoff/Hits/fx/HitSpark3.rows.json build/handoff/Hits/fx/HitSpark4.rows.json

Feel line: your fighter's blow lands and a crisp star of light snaps open on the struck side, its needles flung on along
the blow and slowing, gone before the next blow; a combo's last opens wider with a ring, and a critical bursts a
nine-armed star with a light on the bodies.

The anchor (the builder's hook): CFrame.lookAt(surface, surface + blow), the blow being the attacker-to-target line on
the ground, so the effect's Front (-Z) is the way the blow travels and up is the world's. Frames count from the hit's
frame at 60 a second, on the effects' free clock: the hold never stills it.

Rungs (docs/research/vfx-reference.md, "DESIGN", rule 1): 2 an ordinary hit, 3 a combo's last or the Shade's swing, 4 a
critical. Rung 7 and up is the signature's own effect, not these.

Layers, each offset (handbook/visuals/vfx.md, "Layers"):
- Back: a soft glow card behind, frame 0, gone by 6: the flash under the hero (a backlight, never a puddle of light).
- Star: the hero, the kit's spark sheet as one particle in its three passes (line over fill over its dark twin, ZOffset
  apart), facing the camera, so it reads from any camera. It snaps open in its first frames and breaks outward. Rung 4
  takes the starburst sheet instead, its nine uneven arms, with a small spark over it.
- Needles: fx_streak, stretched along their travel, thrown in a cone along the blow, fast then slow (Drag): the one layer
  that says which way the blow went. A frame after the star.
- Ring (rung 3 and 4): the ring sheet, a breath after, lower and softer.
- Light (rung 4): a PointLight on the bodies, frame 0 to 8.

The block-in is Grey: every colour drawn in its grey (Rows, greyed). The look's colours come at the finish, after the
blockout's verdict. Light only: no wound, nothing left behind, nothing red (AGENTS.md, rule 4). The starburst keeps its
nine uneven arms and is never a fixed decal; a spark is a flash at the impact, never sprayed out of a body (FxKit's
content conditions).
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "handoff" / "Hits" / "fx"

LINE = (255, 246, 230)  # FxKit.Sheet.Line
FILL = (233, 226, 214)  # FxKit.Sheet.Fill
COOL = (91, 86, 112)  # FxKit.Sheet.Cool, the fill's end
DARK = (28, 23, 38)  # FxKit.Sheet.Dark
DARK_TRANSPARENCY = 0.15  # FxKit.Sheet.DarkTransparency
LAYER = 0.05  # FxKit.Sheet.Layer, studs of ZOffset between passes
FRONT = 0.5  # studs of ZOffset toward the camera, so the struck body never cuts the star
WARM = (255, 244, 220)


def c3(rgb):
    return {"Color3": list(rgb)}


def v3(x, y, z):
    return {"Vector3": [x, y, z]}


def sheet_rows(prefix, sheet, life, size, break_at, rotation, why):
    """A kit sheet as one particle in its three passes, facing the camera, from frame 0.
    size: its studs over life as [[t, studs], ...]; break_at: where its fill starts toward the cool tone."""
    common = {
        "Lifetime": [life, life],
        "Speed": [0, 0],
        "Size": size,
        "Rotation": rotation,
        "FlipbookLayout": "Grid4x4",
        "FlipbookMode": "OneShot",
        "LightInfluence": 0,
    }
    passes = {
        "Line": ({"Color": c3(LINE), "LightEmission": 1, "ZOffset": FRONT + LAYER}, f"fx_{sheet}_line"),
        "Fill": ({"Color": [[0, c3(FILL)], [break_at, c3(FILL)], [1, c3(COOL)]], "LightEmission": 0.6, "ZOffset": FRONT}, f"fx_{sheet}_fill"),
        "Dark": ({"Color": c3(DARK), "LightEmission": 0, "Transparency": DARK_TRANSPARENCY, "ZOffset": FRONT - LAYER}, f"fx_{sheet}_dark"),
    }
    rows = {}
    for name, (own, image) in passes.items():
        rows[f"{prefix}{name}"] = {
            "Kind": "Emitter",
            "Image": image,
            "Emitter": {**common, **own},
            "Emit": [[0, 1]],
            "Tracks": {"At": [[0, v3(0, 0, 0)]]},
            "Why": why if name == "Line" else f"{prefix}'s {name.lower()} pass",
        }
    return rows


def needles(count, speed, life, spread, length, frame):
    return {
        "Kind": "Emitter",
        "Image": "fx_streak",
        "Emitter": {
            "EmissionDirection": "Front",
            "SpreadAngle": [spread, spread],
            "Lifetime": life,
            "Speed": speed,
            "Drag": 9,
            "Acceleration": v3(0, 0, 0),  # never falling: light leaving the flash, not something shed (the content check, AR61)
            "Orientation": "VelocityParallel",
            "Size": [[0, length], [0.6, length * 0.7], [1, 0]],
            "Squash": [[0, -1.6], [1, -0.6]],
            "Transparency": [[0, 0], [0.7, 0.1], [1, 1]],
            "Color": c3(LINE),
            "LightEmission": 1,
            "LightInfluence": 0,
            "ZOffset": FRONT + 2 * LAYER,
        },
        "Emit": [[frame, count]],
        "Tracks": {"At": [[0, v3(0, 0, 0)]]},
        "Why": "the needles: thrown along the blow, fast then slow, stretched along their travel; they alone say which way it went",
    }


def back(size, frames):
    return {
        "Kind": "Card",
        "Image": "fx_glow",
        "Color": c3(WARM),
        "Tracks": {
            "At": [[0, v3(0, 0, 0)]],
            "Size": [[0, size, "Quad Out"], [2, size * 1.15, "Quad In"], [frames, 0]],
            "Transparency": [[0, 0.25, "Quad In"], [frames, 0.9]],
        },
        "Why": "the backlight: a soft flash under the star, at the contact, gone in a tenth of a second",
    }


def light(range_, brightness, frames):
    return {
        "Kind": "Light",
        "Range": range_,
        "Color": c3(WARM),
        "Tracks": {
            "At": [[0, v3(0, 0, 0.5)]],
            "Brightness": [[0, brightness, "Quad Out"], [frames, 0]],
        },
        "Why": "the critical's light on the two bodies, no wider than they stand",
    }


def effect(name, why, rows):
    return {"Schema": "rows/1", "Effect": name, "Why": why, "Area": 1, "Grey": True, "Rows": rows}


def build():
    rung2 = {
        "Back": back(2.2, 6),
        **sheet_rows("Star", "spark", 0.22, [[0, 1.4], [0.12, 2.2], [1, 2.6]], 0.3, [0, 360],
                     "the hero: the spark sheet snapping open on the struck side and breaking outward, a quick flick"),
        "Needles": needles(4, [26, 38], [0.12, 0.2], 50, 0.9, 1),
    }
    rung3 = {
        "Back": back(2.8, 7),
        **sheet_rows("Star", "spark", 0.26, [[0, 1.8], [0.12, 2.8], [1, 3.2]], 0.3, [0, 360],
                     "the hero: the spark sheet, wider and a few frames longer than an ordinary hit's"),
        "Needles": needles(6, [30, 44], [0.14, 0.22], 55, 1.1, 1),
        **sheet_rows("Ring", "ring", 0.28, [[0, 1.6], [1, 3.4]], 0.34, [0, 0],
                     "the secondary: the ring sheet a breath after the star, lower and softer"),
    }
    # the ring a breath late: its three passes from frame 2
    for key in ("RingLine", "RingFill", "RingDark"):
        rung3[key]["Emit"] = [[2, 1]]
        rung3[key]["Tracks"] = {"At": [[2, v3(0, 0, 0)]]}
    rung4 = {
        "Back": back(3.4, 8),
        **sheet_rows("Burst", "starburst", 0.36, [[0, 2.2], [0.1, 3.4], [1, 3.8]], 0.36, [0, 360],
                     "the hero: the starburst's nine uneven arms, the critical's own shape"),
        **sheet_rows("Star", "spark", 0.2, [[0, 1.2], [0.12, 1.8], [1, 2]], 0.3, [0, 360],
                     "a small spark over the burst's middle, its crisp core"),
        "Needles": needles(8, [34, 50], [0.16, 0.26], 60, 1.3, 1),
        **sheet_rows("Ring", "ring", 0.3, [[0, 2], [1, 4.2]], 0.34, [0, 0],
                     "the secondary: the ring sheet a breath after, lower and softer"),
        "Light": light(7, 3, 8),
    }
    for key in ("StarLine", "StarFill", "StarDark"):
        rung4[key]["Emitter"]["ZOffset"] += 3 * LAYER  # over the burst
    for key in ("RingLine", "RingFill", "RingDark"):
        rung4[key]["Emit"] = [[2, 1]]
        rung4[key]["Tracks"] = {"At": [[2, v3(0, 0, 0)]]}
    return {
        "HitSpark2": effect("HitSpark2", "A landed hit at rung 2, an ordinary blow: the grey block-in (AR61).", rung2),
        "HitSpark3": effect("HitSpark3", "A landed hit at rung 3, a combo's last or the Shade's swing: the grey block-in (AR61).", rung3),
        "HitSpark4": effect("HitSpark4", "A landed hit at rung 4, a critical: the grey block-in (AR61).", rung4),
    }


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else OUT
    out.mkdir(parents=True, exist_ok=True)
    for name, data in build().items():
        path = out / f"{name}.rows.json"
        path.write_bytes((json.dumps(data, indent=2) + "\n").encode("utf-8"))  # LF, as the repo keeps it
        print(f"wrote {path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else path}")


if __name__ == "__main__":
    main()
