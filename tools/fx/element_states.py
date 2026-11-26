"""The element states' looks (AR48), in grey, as rows files for tools/fx/rows_take.py. Scintilla's.

    py tools/fx/element_states.py [out_dir]        (default: build/handoff/States/fx)
    py tools/fx/element_states.py --pictures       (fx_mote_rim, Sap's mote, into build/handoff/States/pictures)

The looks research picked are Modulo's block-in (tools/blender/element_states_fx.py, `Cues` and `Ice`); these are the
same timings and shapes in the game's rows, from the kit only. FighterController wears each by name while its state
holds (StateBurn, StateChill, StateShock, StateSap; a freeze is the stun's StateFreeze) and ends it at once, so every
row rides the body and holds to a far frame. FreezeBreak is the one free effect: the shell's shatter as the freeze ends,
played where the body stands.

Feel line: a Frost lead's third hit lands, frost climbs the Shade's legs a step a hit, then a shell of ice snaps shut
round it and bursts into chips; a Fire hit leaves embers rising off its shoulders, a Storm hit light crackling over it,
a Void hit dark motes circling in and sinking round it. Quieter than a hit, never hiding the silhouette.

Research's rule for a state (AR48's pass in motion, 2026-11-26): it sits on the body's outline, shows in the gaps between
hits, and takes a shape no hit uses (a hit is a white star, a ring and radial sparks). Nothing at the feet: at the
player's camera the body hides the floor.

Hero shapes (one each, with a direction and an acceleration):
- Burn: a steady stream of few, large tapered embers rising off the head's top and the shoulders' tops beside the mask,
  lifted and drifting outward, so they live against the sky over and beside the silhouette; a few larger still.
- Chill: a crust of ice teeth along the legs' outer edges, front and back corner, pointing out and up, climbing a band a
  third of the fill (StateChill, StateChill2, StateChill3): the shin, then the knee, then the thigh to the hip; the new
  band's teeth snap out from the bottom up.
- Freeze: a shell snapping up out of the crust and shut in 6 frames, its edge flashing once, held clear. Stand-in: the
  kit's shell in its ribs (the faceted shell waits on its mesh). FreezeBreak: chips flung out and falling.
- Shock: a jagged line of three strokes, inked dark under, crawling along a limb's outer edge, three steps up or down it, each lit 4
  frames with a dark frame between, then a gap; the four limbs out of step, so one or two crawl at any moment. Never on
  the head or the chest.
- Sap: motes drawn out of the body, each a dark disc with a thin light rim (the rim carries the read), born just
  outside the arms' outline at the chest and drifting slowly outward and a little up, slowing, fading where they are:
  never sinking, speeding up or stretching (a dark drop running down a body reads as a drip, in a still frame too; the
  content check of 2026-11-26 blocked research's falling for it). Its violet stays a rim at the colour pass.

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
SHORT = 600  # the shock's pattern: 10 s (a shock is 3 s a hit), its look ending there and worn again by the next hit

FIRE = ((255, 233, 176), (255, 138, 61))  # core, body (Config.UIKit's Fire)
FROST = ((244, 253, 255), (143, 227, 255))
STORM = ((255, 242, 251), (255, 111, 216))
SAP_RIM = (226, 218, 236)  # Sap's rim (its disc dark in the picture); its violet only this rim, at the colour pass

START_H = 2.25  # studs: the shell's height as it starts, the crust's top at the hips
SHELL_W, SHELL_D, SHELL_H = 2.35, 1.3, 5.35  # the shell's half width, half depth, height
SHUT = 6  # frames: the shell snaps shut (0.1 s)
ROOT_HEIGHT = 3  # studs: the root over the foot, at scale 1


def effect(name, why, rows):
    return {"Schema": "rows/1", "Effect": name, "Why": why, "Area": 1, "Grey": True, "Rows": rows}


def held(value):
    return [[0, value], [FAR, value]]


# Burn ------------------------------------------------------------------------------------------------------------
CROWN = 2.7  # studs over the root: just under the Brawler's mask top (2.95), so an ember is out over it at once
SHOULDER = (1.55, 1.0)  # the arm's top, beside the mask (its half width 1.35), the body's outline from behind


def ember(at, radius, rate, size, drift, why):
    return {
        "Kind": "Emitter",
        "Body": "HumanoidRootPart",
        "Image": "fx_ember",
        "Emitter": {
            "FlipbookLayout": "Grid2x2",  # one blob an ember (the sheet's four cells), as the kit's note says
            "FlipbookMode": "Loop",
            "FlipbookStartRandom": True,
            "FlipbookFramerate": [0, 0],
            "EmissionDirection": "Top",
            "SpreadAngle": [12, 12],
            "Lifetime": [1.1, 1.5],
            "Speed": [1.8, 2.4],
            "Drag": 1.0,
            "Acceleration": v3(drift, 2.6, 0),  # lifted, and drifting outward, away from the face
            "Orientation": "VelocityParallel",
            "Size": [[0, size * 0.6], [0.12, size], [0.7, size * 0.8], [1, 0]],
            "Squash": [[0, -1.0], [1, -0.4]],
            "Transparency": [[0, 0.2], [0.1, 0], [0.55, 0.05], [0.65, 0.3], [0.75, 0.1], [1, 1]],  # steady, one late flicker
            "Color": [[0, c3(FIRE[0])], [0.3, c3(FIRE[1])], [1, c3(FIRE[1])]],
            "LightEmission": 1,
            "LightInfluence": 0,
            "ZOffset": 0.3,
        },
        "Emit": [[0, 1]],
        "Tracks": {"At": held(at), "Radius": held(radius), "Rate": held(rate)},
        "Why": why,
    }


def burn():
    rows = {
        "Crown": ember(v3(0, CROWN, 0), 0.7, 2.2, 0.3, 0, "the hero: embers rising off the head's top, over the silhouette"),
        "CrownBig": ember(v3(0, CROWN, 0), 0.5, 0.5, 0.48, 0, "a few larger"),
    }
    for name, side in (("Left", -1), ("Right", 1)):
        rows[f"Shoulder{name}"] = ember(v3(SHOULDER[0] * side, SHOULDER[1], 0), 0.4, 1.8, 0.3, 0.6 * side,
                                        "embers off the arm's top, beside the mask, drifting outward")
    return effect("StateBurn", "Burn (Fire), worn while it holds: a steady stream of embers off the head's and shoulders' outline (AR48, Scintilla's grey, research's rule).", rows)


# Chill and Freeze ------------------------------------------------------------------------------------------------
def pointing(d):
    """Tilt (degrees, as Rows applies it: CFrame.Angles(x, y, z)) laying a chip's long axis (its X) along d."""
    n = math.sqrt(sum(c * c for c in d))
    dx, dy, dz = (c / n for c in d)
    c = math.asin(dy)
    b = math.atan2(-dz, dx)
    return v3(0, round(math.degrees(b), 1), round(math.degrees(c), 1))


# the crust's bands: (part, outward side, low, high) in the part's studs; a leg is 1 x 2 x 1, its foot at -1
BANDS = (  # the legs only: the torso's sides are behind the arms
    (("Left Leg", -1, -0.6, -0.08), ("Right Leg", 1, -0.6, -0.08)),  # the shin: never the foot
    (("Left Leg", -1, -0.08, 0.45), ("Right Leg", 1, -0.08, 0.45)),  # the knee
    (("Left Leg", -1, 0.45, 0.98), ("Right Leg", 1, 0.45, 0.98)),  # the thigh, to the hip
)
TEETH = 4  # a band's teeth on each side, front and back corners in turn


def tooth(part, side, y, front, size, born, why):
    half_x = 0.5  # a leg is 1 wide
    z = -0.45 if front else 0.45
    d = (side * 0.65, 0.7, (-0.35 if front else 0.35))  # out from the corner and up
    n = math.sqrt(sum(c * c for c in d))
    base = 0.3 * size  # its root a little in the leg, the rest out of it
    centre = (side * half_x + d[0] / n * base, y + d[1] / n * base, z + d[2] / n * base)
    full = v3(size, round(size * 2.2, 3), round(size * 1.6, 3))  # a chunky tooth (the chip's 1 x 0.142 x 0.347)
    tracks = {
        "At": [[0, v3(*(round(c, 3) for c in centre))]],
        "Tilt": [[0, pointing(d)]],
        "Transparency": held(0.1),  # to the far frame: the look ends at its rows' last key, so code ends it
        "Glow": held(1.4),
    }
    if born is None:
        tracks["Scale"] = [[0, full]]
    else:
        tracks["Scale"] = [[0, v3(0, 0, 0)], [born, v3(0.05, 0.05, 0.05), "Back Out"], [born + 8, full]]
    return {"Kind": "Mesh", "Body": part, "Part": ["FxChip1"], "Color": c3(FROST[0]), "Tracks": tracks, "Why": why}


def crust(step):
    rows = {}
    rng = random.Random(30 + step)
    for band in range(step):
        new = band == step - 1
        for part, side, low, high in BANDS[band]:
            for k in range(TEETH):
                y = low + (high - low) * (k + 0.5) / TEETH
                size = round(rng.uniform(0.55, 0.75), 3)
                born = 1 + 2 * k if new else None  # the new band's teeth snap out from the bottom up
                name = f"B{band + 1}{'L' if side < 0 else 'R'}{k + 1}"
                rows[name] = tooth(part, side, round(y, 3), k % 2 == 0, size, born,
                                   "the hero: an ice tooth on the outline, out and up" if new else "the bands before, held")
    return rows


def chill():
    return {
        f"StateChill{'' if step == 1 else step}": effect(
            f"StateChill{'' if step == 1 else step}",
            f"Chill (Frost), its {('first', 'second', 'third')[step - 1]} third, worn while the fill is in it: the crust on the legs' outline (AR48, Scintilla's grey, research's rule).",
            crust(step),
        )
        for step in (1, 2, 3)
    }


def freeze():
    start_h = START_H
    shell = {  # rides the root (3 over the foot), not grounded: a grounded row's height is the foot's
        "Kind": "Mesh",
        "Body": "HumanoidRootPart",
        "Part": ["FxShell"],
        "Look": "fx_ribs_Grey",
        "Grey": "fx_ribs_Grey",
        "Color": c3(FROST[0]),
        "Tracks": {
            # out of the crust's top and shut: its foot held on the street as it grows
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
LIMBS = (("Left Arm", -1, -0.98), ("Right Arm", 1, -0.98), ("Left Leg", -1, -0.6), ("Right Leg", 1, -0.6))  # outer side, lowest foot
STEPS = 3  # a crawl's steps along the limb
LIT = 4  # frames a step is lit, then one dark: the flicker
SPAN = 1.3  # studs of the limb one step's line covers: two thirds of an arm (in play, 0.95 didn't read)
EDGE = 0.75  # studs out from the limb's middle: off its outer face (0.5), the line's inward jags still outside it
WIDTH = 0.5  # fx_beam's bright middle is about half its width: 0.3 read as a thin white in a dark scribble
INK = (0.75, (28, 22, 36))  # the dark line under each stroke, its width and colour: the line reads on the pale floor too


def up_to(d):
    """Tilt (degrees, as Rows applies it: CFrame.Angles(x, y, z)) laying a beam's up axis along d."""
    n = math.sqrt(sum(c * c for c in d))
    dx, dy, dz = (c / n for c in d)
    z = math.asin(max(-1.0, min(1.0, -dx)))
    x = math.atan2(dz, dy)
    return v3(round(math.degrees(x), 1), 0, round(math.degrees(z), 1))


def zig(rng, side):
    """Four points of a jagged line along a limb's outer edge, from a step's foot: the middle two off the edge by a jag,
    out then in, toward the front or the back, so it's jagged from behind and from the side."""
    lean = rng.choice((-1, 1))
    points = []
    for i in range(4):
        y = SPAN * i / 3 + (rng.uniform(-0.07, 0.07) if 0 < i < 3 else 0)
        jag = (rng.uniform(0.2, 0.3) if i == 1 else -rng.uniform(0.2, 0.3)) if 0 < i < 3 else 0
        points.append((side * (EDGE + 0.75 * jag), y, 0.65 * jag * lean))
    return points


def strokes(points, foot):
    """Each stroke's centre, tilt and half length, point to point."""
    out = []
    for a, b in zip(points, points[1:]):
        d = tuple(q - p for p, q in zip(a, b))
        centre = tuple((p + q) / 2 for p, q in zip(a, b))
        half = math.sqrt(sum(c * c for c in d)) / 2
        out.append((v3(round(centre[0], 3), round(centre[1] + foot, 3), round(centre[2], 3)), up_to(d), round(half, 3)))
    return out


def one_a_frame(keys):
    clean, last = [], -1
    for key in sorted(keys, key=lambda k: k[0]):
        if key[0] > last:
            clean.append(key)
            last = key[0]
    return clean


def crawler(side, lowest, rng):
    """A limb's crawls, four steps up or down it in turn, each lit LIT frames with a dark frame between, then a gap:
    the tracks of its three strokes."""
    top = 0.98 - SPAN
    rows = [{"At": [], "Tilt": [], "Foot": [], "Top": [], "Transparency": [[0, 1]]} for _ in range(3)]
    f, up = rng.randint(2, 30), rng.random() < 0.5
    while f < SHORT - STEPS * (LIT + 1) - 2:
        points = zig(rng, side)
        feet = [lowest + (top - lowest) * s / (STEPS - 1) for s in range(STEPS)]
        if not up:
            feet.reverse()
        first, last = f, f + (STEPS - 1) * (LIT + 1)
        for s, foot in enumerate(feet):
            b = f + s * (LIT + 1)
            for row, (at, tilt, half) in zip(rows, strokes(points, foot)):
                row["At"] += [[b, at], [b + LIT, at]]  # held while lit, moved on in the dark frame
                if s == 0:
                    row["Tilt"] += [[first, tilt], [last + LIT, tilt]]
                    row["Foot"] += [[first, -half], [last + LIT, -half]]
                    row["Top"] += [[first, half], [last + LIT, half]]
                row["Transparency"] += [[b - 1, 1], [b, 0], [b + LIT - 1, 0.3], [b + LIT, 1]]
        f = last + LIT + 1 + rng.randint(14, 26)  # the gap
        up = not up
    for row in rows:
        row["Transparency"].append([SHORT, 1])
        for key in row:
            row[key] = one_a_frame(row[key])
    return rows


def shock():
    rng = random.Random(77)
    rows = {}
    for part, side, lowest in LIMBS:
        for k, tracks in enumerate(crawler(side, lowest, rng)):
            tracks["Width"] = [[0, WIDTH]]
            name = f"{part.replace(' ', '')}{k + 1}"
            rows[f"{name}Ink"] = {
                "Kind": "Beam",
                "Body": part,
                "Low": f"{name}.Low",
                "High": f"{name}.High",
                "Like": name,  # its flicker
                "Image": "fx_beam",
                "Grey": "fx_beam",
                "Color": c3(INK[1]),
                "Beam": {"FaceCamera": True, "LightEmission": 0, "LightInfluence": 0, "TextureMode": "Stretch", "TextureSpeed": 0,
                         "Segments": 1, "ZOffset": 0},
                "Tracks": {"Width": [[0, INK[0]]]},
                "Why": "the dark line under the stroke, so it reads on the pale floor and sky",
            }
            rows[name] = {
                "Kind": "Beam",
                "Body": part,
                "Image": "fx_beam",
                "Grey": "fx_beam",
                "Color": c3(STORM[0]),
                "Beam": {"FaceCamera": True, "LightEmission": 1, "LightInfluence": 0, "TextureMode": "Stretch", "TextureSpeed": 0,
                         "Segments": 1, "ZOffset": 0.1, "Brightness": 2},
                "Tracks": tracks,
                "Why": f"{'the hero: ' if k == 1 else ''}a stroke of a jagged line crawling along the limb's outer edge, lit {LIT} frames a step",
            }
    return effect("StateShock", "Shock (Storm), worn while it holds: jagged lines crawling along the limbs' outline, flickering through the gaps (AR48, Scintilla's grey, research's rule).", rows)


# Sap -------------------------------------------------------------------------------------------------------------
RING = 2.25  # studs out from the body's middle, each side: just past the arms' outer faces (2)
SPOTS = ((-0.6, 1.1), (0, 0.5), (0.6, 0.85))  # each side's spots, (z, height over the root): beside the chest


def sap():
    rows = {}
    for name, side in (("Left", -1), ("Right", 1)):
        for k, (z, y) in enumerate(SPOTS):
            rows[f"Motes{name}{k + 1}"] = {
                "Kind": "Emitter",
                "Body": "HumanoidRootPart",
                "Image": "fx_mote_rim",
                "Emitter": {
                    "LockedToPart": True,  # going with the body
                    "Lifetime": [1.6, 2.2],
                    "EmissionDirection": "Left" if side < 0 else "Right",  # out, away from the body
                    "SpreadAngle": [25, 25],
                    "Speed": [0.5, 0.8],
                    "Drag": 1.3,
                    "Acceleration": v3(0, 0.25, 0),  # slowing as they leave, a little lift: never a sink (the content check)
                    "Size": [[0, 0], [0.1, 0.34], [0.75, 0.34], [1, 0]],
                    "Transparency": [[0, 0], [1, 0]],
                    "Color": c3(SAP_RIM),
                    "LightEmission": 0,
                    "LightInfluence": 0,
                    "ZOffset": 0.2,
                },
                "Emit": [[0, 1]],
                "Tracks": {"At": held(v3(RING * side, y, z)), "Radius": held(0.3), "Rate": held(2)},
                "Why": "the hero: dark motes with a light rim, drawn out of the body, outside its outline" if k == 1 else "the side's next spot",
            }
    return effect("StateSap", "Sap (Void), worn while it holds: rimmed motes drawn out of the body, outside its outline (AR48, Scintilla's grey, research's rule).", rows)


# the mote's picture -----------------------------------------------------------------------------------------------
PICTURES = ROOT / "build" / "handoff" / "States" / "pictures"


def mote_rim(out=PICTURES, side=128):
    """fx_mote_rim: a dark disc with a thin light rim; the rim white, so a Color tints it, the disc dark under any."""
    import subprocess
    import numpy as np
    c = (side - 1) / 2
    yy, xx = np.mgrid[0:side, 0:side]
    rho = np.hypot(xx - c, yy - c) / (side / 2)

    def smooth(a, b, x):
        u = np.clip((x - a) / (b - a), 0, 1)
        return u * u * (3 - 2 * u)

    value = 0.1 + 0.9 * smooth(0.70, 0.78, rho)  # dark inside, white from the rim out
    alpha = 1 - smooth(0.88, 0.98, rho)
    rgba = np.dstack([value, value, value, alpha])
    data = (np.clip(rgba, 0, 1) * 255 + 0.5).astype(np.uint8).tobytes()
    out.mkdir(parents=True, exist_ok=True)
    path = out / "fx_mote_rim.png"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgba", "-s", f"{side}x{side}", "-i", "-",
                    str(path)], input=data, check=True)
    assert alpha[0, 0] < 0.01 and alpha[side // 2, side // 2] > 0.99
    return path


def build():
    looks = {"StateBurn": burn(), **chill(), "StateFreeze": freeze(), "FreezeBreak": freeze_break(), "StateShock": shock(), "StateSap": sap()}
    return looks


def compact(value, depth=0):
    """JSON with a value that fits in 100 characters on one line (a key, a Vector3), so a long look stays small."""
    flat = json.dumps(value)
    if len(flat) <= 100 or not isinstance(value, (list, dict)):
        return flat
    pad, inner = " " * depth, " " * (depth + 1)
    if isinstance(value, list) and all(len(json.dumps(v)) <= 60 for v in value):  # a track's keys, packed to lines
        lines, line = [], []
        for v in value:
            if line and len(", ".join(line)) + len(json.dumps(v)) > 110:
                lines.append(", ".join(line))
                line = []
            line.append(json.dumps(v))
        lines.append(", ".join(line))
        return "[\n" + ",\n".join(inner + text for text in lines) + f"\n{pad}]"
    if isinstance(value, dict):
        items = [f"{inner}{json.dumps(k)}: {compact(v, depth + 1)}" for k, v in value.items()]
        return "{\n" + ",\n".join(items) + f"\n{pad}}}"
    return "[\n" + ",\n".join(f"{inner}{compact(v, depth + 1)}" for v in value) + f"\n{pad}]"


def main():
    if sys.argv[1:2] == ["--pictures"]:
        print("wrote", mote_rim().relative_to(ROOT).as_posix())
        return
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else OUT
    out.mkdir(parents=True, exist_ok=True)
    for name, data in build().items():
        path = out / f"{name}.rows.json"
        path.write_bytes((compact(data) + "\n").encode("utf-8"))
        print(f"wrote {path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else path}")


if __name__ == "__main__":
    main()
