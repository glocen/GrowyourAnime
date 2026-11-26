"""The hit sparks (AR61, docs/asset-requests.md): the shared kit's landed-hit look, one rows effect per rung, written as
rows files for tools/fx/rows_take.py. Scintilla's, the effect family's one script.

    py tools/fx/hit_sparks.py [out_dir]        (default: build/handoff/Hits/fx)
    py tools/fx/rows_take.py build/handoff/Hits/fx/HitSpark2.rows.json build/handoff/Hits/fx/HitSpark3.rows.json build/handoff/Hits/fx/HitSpark4.rows.json

Feel line: your fighter's blow lands and a crisp star of light snaps open on the struck side, its needles flung on along
the blow and slowing, gone before the next blow; a combo's last opens wider with a ring, and a critical bursts a gold
star with a light on the bodies.

The build to research's pick, the star (2026-11-25, 23:18; tools/fx/spark_targets.py, star): the target's levers,
frames and sizes, in the kit's pictures. Nothing new is drawn or uploaded.

The anchor (the builder's hook): CFrame.lookAt(surface, surface + blow), the blow being the attacker-to-target line on
the ground, so the effect's Front (-Z) is the way the blow travels and up is the world's. Frames count from the hit's
frame at 60 a second, on the effects' free clock: the hold never stills it.

Rungs (docs/research/vfx-reference.md, "DESIGN", rule 1): 2 an ordinary hit, 3 a combo's last or the Shade's swing, 4 a
critical. Rung 7 and up is the signature's own effect, not these. Sizes by rung are the target's: 1, 1.35 and 1.7.

Layers, each offset toward the camera (HIT_FRONT, 2.5 studs) so neither body cuts them, the attacker's fist included
(handbook/visuals/vfx.md, "Layers"):
- Back: a soft glow in the hit's colour, frame 0, gone by 6 to 9: the white mass under the hero.
- Star: the hero, the kit's spark sheet as one particle in its three passes (a white line over its colour's fill over
  its ink twin, a little smaller and half seen), facing the camera, so it reads from any camera. It snaps open in its first frames and
  breaks outward. The three passes take one fixed rotation, since each emitter would roll its own. Rung 4 lays a second
  star over it, turned a sixteenth and smaller: the critical's denser burst of straight arms (the target's).
- Lance: the star's long arm, along the blow (the target's "the arm along the blow longest"): one streak particle
  thrown along it. With the needles it's what says which way.
- Needles: fx_streak, stretched along their travel, thrown in a cone along the blow, fast then slow (Drag): a frame
  after the star.
- Ring (rungs 3 and 4): the ring sheet, a breath after, white and its hue only; the step from rung 2.
- Light (rung 4): a gold PointLight on the bodies, frame 0 to 12.

Colours: the hit numbers' (UIKit.Numbers): the plain hit's warm white at rungs 2 and 3, the critical's gold at 4; white
only in the line; the ink is the kit's Sheet Dark, the star's read on the pale deck. Light only: no wound, nothing left
behind, nothing red (AGENTS.md, rule 4). A spark is a flash at the impact, never sprayed out of a body (FxKit's content
conditions); the needles stay thin straight tapered light, never dark, never falling (the content check, AR61).
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "handoff" / "Hits" / "fx"

# The kit sheet's own tones: the shared helpers below (sheet_rows, needles) keep them, for the effects that import them
# (shade_tells, keeper_moves, support_looks, element_states). The hit sparks' finish takes its own colours after.
LINE = (255, 246, 230)  # FxKit.Sheet.Line
FILL = (233, 226, 214)  # FxKit.Sheet.Fill
COOL = (91, 86, 112)  # FxKit.Sheet.Cool, the fill's end
DARK = (28, 23, 38)  # FxKit.Sheet.Dark
DARK_TRANSPARENCY = 0.15  # FxKit.Sheet.DarkTransparency
LAYER = 0.05  # FxKit.Sheet.Layer, studs of ZOffset between passes
FRONT = 0.5  # studs of ZOffset toward the camera, so the struck body never cuts the star
HIT_FRONT = 2.5  # the hit sparks' own: the attacker's fist stands between the camera and the contact, and at FRONT it hid
# the bloom and half the star (AR61's next take, 2026-11-26). ZOffset draws nearer without changing the screen size.
WARM = (255, 244, 220)

PLAIN = (248, 241, 223)  # UIKit.Numbers.Plain, #F8F1DF: an ordinary hit
GOLD = (255, 207, 77)  # UIKit.Numbers.Critical, #FFCF4D: a critical
WHITE = (255, 255, 255)
INK = DARK  # the ink twin
SIZE = {2: 1.0, 3: 1.35, 4: 1.7}  # the target's sizes by rung


def c3(rgb):
    return {"Color3": list(rgb)}


def v3(x, y, z):
    return {"Vector3": [x, y, z]}


def dim(rgb, k):
    return tuple(round(v * k) for v in rgb)


def scaled(seq, k):
    return [[t, round(v * k, 3)] for t, v in seq]


def sheet_rows(prefix, sheet, life, size, break_at, rotation, why):
    """A kit sheet as one particle in its three passes, facing the camera, from frame 0, all three at one angle
    (`rotation`, degrees): a range would roll each pass its own, so line, fill and dark would part.
    size: its studs over life as [[t, studs], ...]; break_at: where its fill starts toward the cool tone."""
    common = {
        "Lifetime": [life, life],
        "Speed": [0, 0],
        "Size": size,
        "Rotation": [rotation, rotation],
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


def star_passes(prefix, sheet, life, size, hue, rotation, why, z=0.0, frame=0, ink=True):
    """The hit sparks' finish: a kit sheet as one particle in its passes, facing the camera, on `frame`: a white line over
    the hue's fill, over its ink twin when `ink`. The ink sits inside the light (a tenth smaller, half seen), a shade
    under the arms on the pale deck: larger, it showed past them as dark spikes and a dark hoop (AR61's next take).
    One rotation for all, so they lie as one."""
    common = {
        "Lifetime": [life, life],
        "Speed": [0, 0],
        "Rotation": [rotation, rotation],
        "FlipbookLayout": "Grid4x4",
        "FlipbookMode": "OneShot",
        "LightInfluence": 0,
    }
    passes = {
        "Line": ({"Size": size, "Color": c3(WHITE), "LightEmission": 1, "ZOffset": HIT_FRONT + z + LAYER}, f"fx_{sheet}_line"),
        "Fill": ({"Size": size, "Color": [[0, c3(hue)], [0.4, c3(hue)], [1, c3(dim(hue, 0.6))]], "LightEmission": 0.8,
                  "ZOffset": HIT_FRONT + z}, f"fx_{sheet}_fill"),
        "Dark": ({"Size": scaled(size, 0.9), "Color": c3(INK), "LightEmission": 0, "Transparency": [[0, 0.5], [0.6, 0.6], [1, 1]],
                  "ZOffset": HIT_FRONT + z - LAYER}, f"fx_{sheet}_dark"),
    }
    if not ink:
        del passes["Dark"]
    rows = {}
    for name, (own, image) in passes.items():
        rows[f"{prefix}{name}"] = {
            "Kind": "Emitter",
            "Image": image,
            "Emitter": {**common, **own},
            "Emit": [[frame, 1]],
            "Tracks": {"At": [[frame, v3(0, 0, 0)]]},
            "Why": why if name == "Line" else f"{prefix}'s {name.lower()} pass" + (", its ink twin: its read on the pale deck" if name == "Dark" else ""),
        }
    return rows


def lance(rung, hue):
    """The star's long arm along the blow: one streak thrown along it, fast then slow. Its ink twin is gone: it drew a
    dark spike past the light one (AR61's next take, 2026-11-26)."""
    k = SIZE[rung]
    # Drawn about 2 studs a size long (Size x 2^-Squash), from the contact along the blow: a particle is centred on its
    # place, so it starts half its length ahead. Centred on the contact, half of it ran back over the attacker
    # (AR61's quarter, 2026-11-25).
    length = round(1.1 * k, 3)
    ahead = v3(0, 0, round(-1.0 * k, 3))
    common = {
        "EmissionDirection": "Front",
        "SpreadAngle": [0, 0],
        "Lifetime": [0.2 + 0.03 * (rung - 2)] * 2,
        "Speed": [round(10 * k, 2)] * 2,
        "Drag": 9,
        "Acceleration": v3(0, 0, 0),
        "Orientation": "VelocityParallel",
        "Rotation": [0, 0],
        "LightInfluence": 0,
    }
    size = [[0, round(length * 0.7, 3)], [0.15, length], [1, round(length * 0.4, 3)]]
    return {
        "Lance": {
            "Kind": "Emitter", "Image": "fx_streak",
            "Emitter": {**common, "Size": size, "Squash": [[0, -0.8], [1, -1.2]],
                        "Transparency": [[0, 0], [0.5, 0.05], [1, 1]], "Color": [[0, c3(WHITE)], [0.3, c3(hue)], [1, c3(hue)]],
                        "LightEmission": 1, "ZOffset": HIT_FRONT + 6 * LAYER},
            "Emit": [[0, 1]], "Tracks": {"At": [[0, ahead]]},
            "Why": "the star's long arm, along the blow: snapped out on the hit and running on, fast then slow",
        },
    }


def needles(count, speed, life, spread, length, frame, direction="Front", colour=LINE, z=2 * LAYER):
    return {
        "Kind": "Emitter",
        "Image": "fx_streak",
        "Emitter": {
            "EmissionDirection": direction,
            "SpreadAngle": [spread, spread],
            "Lifetime": life,
            "Speed": speed,
            "Drag": 9,
            "Acceleration": v3(0, 0, 0),  # never falling: light leaving the flash, not something shed (the content check, AR61)
            "Orientation": "VelocityParallel",
            "Size": [[0, length], [0.6, length * 0.7], [1, 0]],
            "Squash": [[0, -1.6], [1, -0.6]],
            "Transparency": [[0, 0], [0.7, 0.1], [1, 1]],
            "Color": c3(colour),
            "LightEmission": 1,
            "LightInfluence": 0,
            "ZOffset": FRONT + z,
        },
        "Emit": [[frame, count]],
        "Tracks": {"At": [[0, v3(0, 0, 0)]]},
        "Why": "the needles: thrown along the blow, fast then slow, stretched along their travel; they alone say which way it went",
    }


def back(size, frames, hue):
    """One soft light under the star, drawn toward the camera just behind its passes. A card here sat between the two
    bodies and they hid it: the build had no bloom where the target's peak has one (AR61's quarter, 2026-11-25)."""
    return {
        "Kind": "Emitter",
        "Image": "fx_glow",
        "Emitter": {
            "Lifetime": [round(frames / 60, 4)] * 2,
            "Speed": [0, 0],
            "Rotation": [0, 0],
            "Size": [[0, size], [round(min(2 / frames, 0.5), 3), round(size * 1.15, 3)], [1, 0]],
            "Transparency": [[0, 0.2], [1, 0.9]],
            "Color": c3(hue),
            "LightEmission": 1,
            "LightInfluence": 0,
            "ZOffset": HIT_FRONT - 5 * LAYER,
        },
        "Emit": [[0, 1]],
        "Tracks": {"At": [[0, v3(0, 0, 0)]]},
        "Why": "the backlight: a soft flash under the star, at the contact, gone in a tenth of a second",
    }


def light(range_, brightness, frames):
    return {
        "Kind": "Light",
        "Range": range_,
        "Color": c3(GOLD),
        "Tracks": {
            "At": [[0, v3(0, 0, 0.5)]],
            "Brightness": [[0, brightness, "Quad Out"], [frames, 0]],
        },
        "Why": "the critical's gold light on the two bodies, no wider than they stand",
    }


def star_size(rung):
    """The spark sheet's studs over its life: open in its first frames, then swelling a little as it breaks."""
    k = SIZE[rung]
    return [[0, round(1.4 * k, 3)], [0.12, round(2.2 * k, 3)], [1, round(2.6 * k, 3)]]


def effect(name, why, rows):
    return {"Schema": "rows/1", "Effect": name, "Why": why, "Area": 1, "Grey": False, "Rows": rows}


def build():
    rung2 = {
        "Back": back(2.2, 6, PLAIN),
        **star_passes("Star", "spark", 0.2, star_size(2), PLAIN, 0,
                     "the hero: the spark sheet snapping open on the struck side and breaking outward, a quick flick"),
        **lance(2, PLAIN),
        "Needles": needles(5, [26, 38], [0.12, 0.2], 50, 0.9, 1, colour=PLAIN, z=HIT_FRONT - FRONT + 4 * LAYER),
    }
    rung3 = {
        "Back": back(3.2, 8, PLAIN),
        **star_passes("Star", "spark", 0.24, star_size(3), PLAIN, 0,
                     "the hero: the spark sheet, a third wider and a few frames longer than an ordinary hit's"),
        **lance(3, PLAIN),
        "Needles": needles(8, [32, 46], [0.14, 0.22], 55, 1.15, 1, colour=PLAIN, z=HIT_FRONT - FRONT + 4 * LAYER),
        **star_passes("Ring", "ring", 0.3, [[0, 1.6], [1, 5.0]], PLAIN, 0,
                     "the step from rung 2: the ring sheet a breath after the star, swelling past it", z=-3 * LAYER, frame=2, ink=False),
    }
    rung4 = {
        "Back": back(4.0, 9, GOLD),
        **star_passes("Star", "spark", 0.28, star_size(4), GOLD, 0,
                     "the hero: the spark sheet in the critical's gold, the widest"),
        **star_passes("Star2", "spark", 0.24, scaled(star_size(4), 0.72), GOLD, 22.5,
                     "a second star over it, turned a sixteenth: the critical's denser burst of straight arms", z=2 * LAYER, ink=False),
        **lance(4, GOLD),
        "Needles": needles(12, [36, 52], [0.16, 0.26], 60, 1.3, 1, colour=GOLD, z=HIT_FRONT - FRONT + 4 * LAYER),
        **star_passes("Ring", "ring", 0.32, [[0, 2.0], [1, 6.0]], GOLD, 0,
                     "the ring sheet a breath after, swelling past the star", z=-3 * LAYER, frame=2, ink=False),
        "Light": light(7, 3, 12),
    }
    return {
        "HitSpark2": effect("HitSpark2", "A landed hit at rung 2, an ordinary blow: the star (AR61).", rung2),
        "HitSpark3": effect("HitSpark3", "A landed hit at rung 3, a combo's last or the Shade's swing: the star with its ring (AR61).", rung3),
        "HitSpark4": effect("HitSpark4", "A landed hit at rung 4, a critical: the gold star (AR61).", rung4),
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
