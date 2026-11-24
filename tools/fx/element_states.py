"""The element states' looks (AR48), in grey, as rows files for tools/fx/rows_take.py. Scintilla's.

    py tools/fx/element_states.py [out_dir]        (default: build/handoff/States/fx)

The looks research picked are Modulo's block-in (tools/blender/element_states_fx.py, `Cues` and `Ice`); these are the
same timings and shapes in the game's rows, from the kit only. FighterController wears each by name while its state
holds (StateBurn, StateChill, StateShock, StateSap; a freeze is the stun's StateFreeze) and ends it at once, so every
row rides the body and holds to a far frame. FreezeBreak is the one free effect: the shell's shatter as the freeze ends,
played where the body stands.

Feel line: a Frost lead's third hit lands, frost climbs the Shade's legs a step a hit, then a shell of ice snaps shut
round it and bursts into chips; a Fire hit leaves embers rising off its shoulders, a Storm hit light crackling over it,
a Void hit dark motes circling in and sinking round it. Quieter than a hit, never hiding the silhouette.

Hero shapes (one each, with a direction and an acceleration):
- Burn: tapered embers off the shoulders' tops, outside the head's column, lifted fast, drifting outward, flickering out
  above the head; one in seven larger.
- Chill: a sleeve of frost round the legs, a step a third of the fill (StateChill, StateChill2, StateChill3), each
  climbing from the last step's top. Stand-in: the kit's column (the crown of teeth waits on its mesh).
- Freeze: a shell snapping up out of the sleeve and shut in 6 frames, its edge flashing once, held clear. Stand-in: the
  kit's shell in its ribs (the faceted shell waits on its mesh). FreezeBreak: chips flung out and falling.
- Shock: arcs leaping off the body in bursts of three frames, about three a second: one big arc a burst (2 studs) and
  one or two smaller, a white core in a glow, never on the head. Stand-in: a bowed beam (the jagged arc waits on its
  image).
- Sap: dark motes circling in round the upper body and sinking slowly, easing out, never falling or stretching (a dark
  falling drop reads as a drip). Its violet rim waits on the colour pass.

Written at a body of scale 1 (R6, 5 studs, the root 3 over the foot): Area 1, so a Shade's scale scales it.
"""
import json
import math
import random
import sys
from pathlib import Path

from hit_sparks import c3, v3

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "handoff" / "States" / "fx"
FAR = 3600  # frames: a look holds to here, and FighterController ends it when its state ends
SHORT = 1200  # the shock's pattern: 20 s, worn again by the next hit past it

FIRE = ((255, 233, 176), (255, 138, 61))  # core, body (Config.UIKit's Fire)
FROST = ((244, 253, 255), (143, 227, 255))
STORM = ((255, 242, 251), (255, 111, 216))
VOID_DARK = (23, 18, 31)  # Sap is dark first; its violet only a rim, at the colour pass

LEVELS = (0.0, 0.75, 1.5, 2.25)  # studs: the frost's top at each third, feet to hips (Modulo's)
SHELL_W, SHELL_D, SHELL_H = 2.35, 1.3, 5.35  # the shell's half width, half depth, height
SHUT = 6  # frames: the shell snaps shut (0.1 s)
ROOT_HEIGHT = 3  # studs: the root over the foot, at scale 1


def effect(name, why, rows):
    return {"Schema": "rows/1", "Effect": name, "Why": why, "Area": 1, "Grey": True, "Rows": rows}


def held(value):
    return [[0, value], [FAR, value]]


# Burn ------------------------------------------------------------------------------------------------------------
def ember(side, rate, size, why):
    return {
        "Kind": "Emitter",
        "Body": "HumanoidRootPart",
        "Image": "fx_ember",
        "Emitter": {
            "EmissionDirection": "Top",
            "SpreadAngle": [25, 25],
            "Lifetime": [0.8, 1.2],
            "Speed": [1.5, 2.6],
            "Drag": 1.4,
            "Acceleration": v3(0.7 * side, 3.5, 0),  # lifted, and drifting outward, away from the face
            "Orientation": "VelocityParallel",
            "Size": [[0, size], [0.6, size * 0.75], [1, 0]],
            "Squash": [[0, -1.2], [1, -0.5]],
            "Transparency": [[0, 0], [0.15, 0.35], [0.3, 0.05], [0.45, 0.4], [0.6, 0.1], [0.8, 0.5], [1, 1]],  # the flicker
            "Color": [[0, c3(FIRE[0])], [0.35, c3(FIRE[1])], [1, c3(FIRE[1])]],
            "LightEmission": 1,
            "LightInfluence": 0,
            "ZOffset": 0.3,
        },
        "Emit": [[0, 2]],
        "Tracks": {"At": held(v3(1.0 * side, 1.1, 0)), "Radius": held(0.3), "Rate": held(rate)},
        "Why": why,
    }


def burn():
    rows = {}
    for name, side in (("Left", -1), ("Right", 1)):
        rows[f"Embers{name}"] = ember(side, 7.5, 0.14, "the hero: embers off the shoulder's top, outside the head's column")
        rows[f"Big{name}"] = ember(side, 1.2, 0.24, "one in seven larger")
    return effect("StateBurn", "Burn (Fire), worn while it holds: embers rising off the shoulders (AR48, Scintilla's grey).", rows)


# Chill and Freeze ------------------------------------------------------------------------------------------------
def sleeve(step):
    low, high = LEVELS[step - 1], LEVELS[step]
    return {
        "Kind": "Mesh",
        "Body": "HumanoidRootPart",
        "Ground": True,
        "Part": ["FxColumn"],
        "Look": "fx_rise_Grey",
        "Grey": "fx_rise_Grey",
        "Color": c3(FROST[1]),
        "Tracks": {
            "Scale": [[0, v3(1.1, max(low, 0.05) / 2, 1.1), "Back Out"], [9, v3(1.1, high / 2, 1.1)], [FAR, v3(1.1, high / 2, 1.1)]],
            "Transparency": [[0, 0.6 if step == 1 else 0.35, "Quad Out"], [6, 0.35], [FAR, 0.35]],
            "Glow": [[0, 2.2, "Quad Out"], [9, 1.2], [FAR, 1.2]],
        },
        "Why": "the hero: frost climbing the legs from the last step's top to this one's, snapping up (Back Out)",
    }


def chill():
    return {
        f"StateChill{'' if step == 1 else step}": effect(
            f"StateChill{'' if step == 1 else step}",
            f"Chill (Frost), its {('first', 'second', 'third')[step - 1]} third, worn while the fill is in it (AR48, Scintilla's grey).",
            {"Sleeve": sleeve(step)},
        )
        for step in (1, 2, 3)
    }


def freeze():
    start_h = LEVELS[3]
    shell = {  # rides the root (3 over the foot), not grounded: a grounded row's height is the foot's
        "Kind": "Mesh",
        "Body": "HumanoidRootPart",
        "Part": ["FxShell"],
        "Look": "fx_ribs_Grey",
        "Grey": "fx_ribs_Grey",
        "Color": c3(FROST[0]),
        "Tracks": {
            # out of the sleeve's top and shut: its foot held on the street as it grows
            "At": [[0, v3(0, start_h / 2 - ROOT_HEIGHT, 0), "Quart Out"], [SHUT, v3(0, SHELL_H / 2 - ROOT_HEIGHT, 0)], [FAR, v3(0, SHELL_H / 2 - ROOT_HEIGHT, 0)]],
            "Scale": [[0, v3(SHELL_W * 0.85, start_h / 2, SHELL_D * 0.85), "Quart Out"], [SHUT, v3(SHELL_W, SHELL_H / 2, SHELL_D)],
                      [FAR, v3(SHELL_W, SHELL_H / 2, SHELL_D)]],
            "Transparency": [[0, 0.3, "Quad Out"], [SHUT + 2, 0.55], [FAR, 0.55]],  # held clear: the body shows through
            "Glow": [[0, 1.5, "Linear"], [SHUT, 1.5, "Linear"], [SHUT + 1, 4, "Quad Out"], [SHUT + 3, 1.2], [FAR, 1.2]],  # its edge flashes once
        },
        "Why": "the hero: a shell of ice snapping up out of the frost and shut round the body",
    }
    return effect("StateFreeze", "Freeze (Frost), the stun's look: the shell shut round the body (AR48, Scintilla's grey).", {"Shell": shell})


def freeze_break():
    rng = random.Random(48)
    rows = {}
    frames = 24  # 0.4 s, as Modulo's shatter
    for k in range(10):
        a = 2 * math.pi * (k + rng.uniform(-0.3, 0.3)) / 10
        out = (math.cos(a), math.sin(a))
        h = rng.uniform(0.25, 0.9) * SHELL_H
        p0 = (out[0] * SHELL_W * 0.9, h, out[1] * SHELL_D * 0.9)
        speed, up = rng.uniform(3, 5), rng.uniform(1.5, 3)
        spin = [rng.uniform(-1, 1) * rng.uniform(360, 720) for _ in range(3)]
        at, tilt = [], []
        for f in range(0, frames + 1, 3):
            t = f / 60
            at.append([f, v3(round(p0[0] + out[0] * speed * t, 3), round(p0[1] + up * t - 12.5 * t * t, 3), round(p0[2] + out[1] * speed * t, 3))])
            tilt.append([f, v3(*(round(s * t, 1) for s in spin))])
        size = rng.uniform(0.45, 0.65)
        rows[f"Chip{k + 1}"] = {
            "Kind": "Mesh",
            "Part": [f"FxChip{k % 3 + 1}"],
            "Color": c3(FROST[0]),
            "Tracks": {
                "At": at,
                "Tilt": tilt,
                "Scale": [[0, v3(size, size, size), "Quad In"], [frames, v3(size * 0.3, size * 0.3, size * 0.3)]],
                "Transparency": [[0, 0.1, "Quad In"], [frames, 1]],
                "Glow": [[0, 2, "Quad Out"], [frames, 0.5]],
            },
            "Why": "the shell broken into chips, flung out and falling: ice, not the body",
        }
    return effect("FreezeBreak", "The freeze's end: the shell bursts into chips where the body stands (AR48, Scintilla's grey).", rows)


# Shock -----------------------------------------------------------------------------------------------------------
GAPS = (23, 19, 24, 21, 27, 24, 24, 20)  # frames between bursts, Modulo's pattern (SHOCK), about three a second
ARCS = {  # name: (part, at, tilt, half length, big)
    "BigLeg": ("Left Leg", (-0.6, 0.2, 0), (0, 0, -25), 1.0, True),
    "BigChest": ("Torso", (0.55, -0.35, -0.6), (0, 0, 30), 0.9, True),
    "BigArm": ("Right Arm", (0.6, 0, 0), (0, 0, 15), 0.9, True),
    "SmallLeg": ("Right Leg", (0.6, 0, -0.3), (0, 0, 20), 0.55, False),
    "SmallArm": ("Left Arm", (-0.6, -0.2, 0), (0, 0, -20), 0.5, False),
    "SmallBack": ("Torso", (-0.5, -0.6, 0.6), (0, 0, -35), 0.5, False),
}


def bursts():
    out, f, k = [], 0, 0
    while f < SHORT - 4:
        out.append(f)
        f += GAPS[k % len(GAPS)]
        k += 1
    return out


def lit(frames):
    keys = [[0, 1, "Linear"]]
    for b in frames:
        keys += [[max(b - 1, 0) if b else 0, 1, "Linear"], [b, 0, "Linear"], [b + 1, 0.25, "Linear"], [b + 2, 0.55, "Linear"], [b + 3, 1, "Linear"]]
    keys.append([SHORT, 1])
    clean, last = [], -1
    for key in keys:  # one key a frame
        if key[0] > last:
            clean.append(key)
            last = key[0]
    return clean


def arc(name, frames, core):
    part, at, tilt, half, big = ARCS[name]
    width = (0.17 if big else 0.1) * (0.4 if core else 1)
    keys = lit(frames)
    if not core:
        keys = [[f, min(1, v + 0.3), *e] for f, v, *e in keys]  # the glow softer than its core
    return {
        "Kind": "Beam",
        "Body": part,
        "Image": "fx_beam",
        "Grey": "fx_beam",
        "Color": c3(STORM[0] if core else STORM[1]),
        "Beam": {"FaceCamera": True, "LightEmission": 1, "LightInfluence": 0, "TextureMode": "Stretch", "TextureSpeed": 0,
                 "Segments": 10, "CurveSize0": 0.6 if big else 0.35, "CurveSize1": -0.4 if big else -0.25},
        "Tracks": {
            "At": [[0, v3(*at)]],
            "Tilt": [[0, v3(*tilt)]],
            "Foot": [[0, -half]],
            "Top": [[0, half]],
            "Width": [[0, width]],
            "Transparency": keys,
        },
        "Why": f"{'the hero: ' if big else ''}an arc leaping off the body, {'its white core' if core else 'its glow'}; never on the head",
    }


def shock():
    all_bursts = bursts()
    plays = {name: [] for name in ARCS}
    rng = random.Random(77)
    bigs = [n for n, a in ARCS.items() if a[4]]
    smalls = [n for n, a in ARCS.items() if not a[4]]
    for i, b in enumerate(all_bursts):
        plays[bigs[i % 3]].append(b)
        for name in rng.sample(smalls, 2 if i == 0 else rng.randint(1, 2)):
            plays[name].append(b)
    rows = {}
    for name in ARCS:
        rows[f"{name}Glow"] = arc(name, plays[name], False)
        rows[f"{name}Core"] = arc(name, plays[name], True)
    return effect("StateShock", "Shock (Storm), worn while it holds: arcs crackling over the body (AR48, Scintilla's grey).", rows)


# Sap -------------------------------------------------------------------------------------------------------------
def sap():
    motes = {
        "Kind": "Emitter",
        "Body": "HumanoidRootPart",
        "Image": "fx_glow",
        "Emitter": {
            "LockedToPart": True,  # circling with the carrier's turn, and going with the body
            "Lifetime": [1.3, 2.0],
            "EmissionDirection": "Bottom",
            "Speed": [0.5, 0.8],
            "Drag": 1.2,
            "Acceleration": v3(0, 0, 0),  # sinking slowly from a small start, easing out: never speeding up, never a fall (the content check)
            "Size": [[0, 0], [0.08, 0.28], [0.5, 0.28], [1, 0]],
            "Transparency": [[0, 0.08], [1, 0.08]],
            "Color": c3(VOID_DARK),
            "LightEmission": 0,
            "LightInfluence": 0,
            "ZOffset": 0.2,
        },
        "Emit": [[0, 6]],
        "Tracks": {
            "At": held(v3(0, 0.9, 0)),
            "Radius": held(1.5),
            "Rate": held(12),
            "Spin": [[0, 0, "Linear"], [FAR, round(63 * FAR / 60)]],  # 1.1 a second round the body
        },
        "Why": "the hero: dark motes circling in round the upper body and sinking, gone above the knees",
    }
    return effect("StateSap", "Sap (Void), worn while it holds: dark motes sinking round the body (AR48, Scintilla's grey).", {"Motes": motes})


def build():
    looks = {"StateBurn": burn(), **chill(), "StateFreeze": freeze(), "FreezeBreak": freeze_break(), "StateShock": shock(), "StateSap": sap()}
    return looks


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else OUT
    out.mkdir(parents=True, exist_ok=True)
    for name, data in build().items():
        path = out / f"{name}.rows.json"
        path.write_bytes((json.dumps(data, indent=1) + "\n").encode("utf-8"))
        print(f"wrote {path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else path}")


if __name__ == "__main__":
    main()
