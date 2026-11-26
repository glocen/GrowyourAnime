"""The element states' looks (AR48), in grey, as rows files for tools/fx/rows_take.py. Scintilla's.

    py tools/fx/element_states.py [out_dir]        (default: build/handoff/States/fx)
    py tools/fx/element_states.py --pictures       (fx_mote_rim, Sap's mote, into build/handoff/States/pictures)

The looks research picked are Modulo's block-in (tools/blender/element_states_fx.py, `Cues` and `Ice`); these are the
same timings and shapes in the game's rows, from the kit only. FighterController wears each by name while its state
holds (StateBurn, StateShock, StateSap; a freeze is the stun's StateFreeze; a chill wears none) and ends it at once,
so every row rides the body and holds to a far frame. FreezeBreak is the one free effect: the shell's shatter as the
freeze ends, played where the body stands.

Feel line: a Frost lead's third hit lands, a shell of ice snaps shut round the Shade and bursts into chips; a Fire hit
leaves embers rising off its head and shoulders, a Storm hit light crawling along its arms, a Void hit dark motes drawn
out of it. Quieter than a hit, never hiding the silhouette.

Research's rule for a state (AR48's pass in motion, 2026-11-26): it sits on the body's outline, shows in the gaps between
hits, and takes a shape no hit uses (a hit is a white star, a ring and radial sparks). Nothing at the feet: at the
player's camera the body hides the floor.

Hero shapes (one each, with a direction and an acceleration):
- Burn: a steady stream of few tapered embers, each about the size of the foe's hand, rising off the head's top and
  the shoulders' tops beside the mask, lifted and drifting outward, so they live against the sky over and beside the
  silhouette; a few larger still.
- Chill: no look. Research's pass of 2026-11-26 dropped its crust on the legs (the lead hides them at the player's
  camera): Freeze carries Frost alone, and a chill keeps its slow and its numbers.
- Freeze: a shell snapping up from the street and shut in 6 frames, its edge flashing once, held clear. Stand-in: the
  kit's shell in its ribs (the faceted shell waits on its mesh). FreezeBreak: chips flung out and falling.
- Shock: a jagged line of five strokes, inked dark under, down an arm's outer edge from the shoulder to the hand (the
  arms only: research's pass, 2026-11-26), lit stroke by stroke as a crawl runs down or up it, then the whole line at
  once, then a gap; the two arms out of step. Never on the head, the chest or the legs.
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
SAP_RIM = (211, 186, 255)  # Sap's rim, its disc dark in the picture: Void's violet (#B58CFF) lifted toward white to the
# grey pass's value (about 200 of 255), so the rim reads on the dark robe as it did in grey; the violet only this rim

START_H = 2.25  # studs: the shell's height as it starts, at the hips
SHELL_W, SHELL_D, SHELL_H = 2.35, 1.3, 5.35  # the shell's half width, half depth, height
SHUT = 6  # frames: the shell snaps shut (0.1 s)
ROOT_HEIGHT = 3  # studs: the root over the foot, at scale 1


COLOURED = {"StateBurn", "StateFreeze", "FreezeBreak", "StateSap"}  # past research's grey pass, in their colour (2026-11-26)


def effect(name, why, rows):
    return {"Schema": "rows/1", "Effect": name, "Why": why, "Area": 1, "Grey": name not in COLOURED, "Rows": rows}


def held(value):
    return [[0, value], [FAR, value]]


# Burn ------------------------------------------------------------------------------------------------------------
CROWN = 2.9  # studs over the root: at the Brawler's mask top (2.95), so an ember is out over it at once
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
        "Crown": ember(v3(0, CROWN, 0), 0.7, 1.4, 0.9, 0, "the hero: embers about the size of the foe's hand, rising off the head's top, over the silhouette"),
        "CrownBig": ember(v3(0, CROWN, 0), 0.5, 0.35, 1.2, 0, "a few larger"),
    }
    for name, side in (("Left", -1), ("Right", 1)):
        rows[f"Shoulder{name}"] = ember(v3(SHOULDER[0] * side, SHOULDER[1], 0), 0.4, 1.0, 0.9, 0.6 * side,
                                        "embers off the arm's top, beside the mask, drifting outward")
    return effect("StateBurn", "Burn (Fire), worn while it holds: a steady stream of embers off the head's and shoulders' outline (AR48, Scintilla's grey, research's rule).", rows)


# Freeze -----------------------------------------------------------------------------------------------------
def freeze():
    start_h = START_H
    shell = {  # rides the root (3 over the foot), not grounded: a grounded row's height is the foot's
        "Kind": "Mesh",
        "Body": "HumanoidRootPart",
        "Part": ["FxShell"],
        "Look": "fx_ribs_Grey",
        "Grey": "fx_ribs_Grey",
        "Color": c3(FROST[1]),  # Frost's blue, the ribs' white edge flashing over it: Modulo's picked colour
        "Tracks": {
            # up from the hips and shut: its foot held on the street as it grows
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
            "Color": c3(FROST[1]),
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
ARMS = (("Left Arm", -1), ("Right Arm", 1))  # the arms' outline only, upper arm to hand (research, 2026-11-26)
STROKES = 5  # a crawl's line, shoulder to hand
TOP, HAND = 0.95, -0.98  # studs up the arm (2 long): its line's ends
LIT = 4  # frames a stroke is lit as the crawl passes it
STAGGER = 2  # frames from one stroke's light to the next: the crawl's speed
SNAP = 3  # frames the whole line is lit once after the crawl
EDGE = 0.85  # studs out from the arm's middle: off its outer face (0.5), the line's inward jags still outside it
JAG = (0.25, 0.38)  # studs a point stands off the edge, out then in
WIDTH = 0.6  # fx_beam's bright middle is about half its width: it reads at the sheet's scale, a phone's
INK = (0.95, (28, 22, 36))  # the dark line under each stroke, its width and colour: the line reads on the pale floor too


def up_to(d):
    """Tilt (degrees, as Rows applies it: CFrame.Angles(x, y, z)) laying a beam's up axis along d."""
    n = math.sqrt(sum(c * c for c in d))
    dx, dy, dz = (c / n for c in d)
    z = math.asin(max(-1.0, min(1.0, -dx)))
    x = math.atan2(dz, dy)
    return v3(round(math.degrees(x), 1), 0, round(math.degrees(z), 1))


def zig(rng, side):
    """The points of a jagged line down an arm's outer edge, shoulder to hand: each inner point off the edge by a jag,
    out and in by turns, leaning toward the front or the back, so it's jagged from behind and from the side."""
    lean = rng.choice((-1, 1))
    points = []
    for i in range(STROKES + 1):
        y = TOP + (HAND - TOP) * i / STROKES + (rng.uniform(-0.06, 0.06) if 0 < i < STROKES else 0)
        jag = 0 if i in (0, STROKES) else rng.uniform(*JAG) * (1 if i % 2 else -1)
        points.append((side * (EDGE + 0.8 * jag), y, 0.5 * jag * lean))
    return points


def strokes(points):
    """Each stroke's centre, tilt and half length, point to point."""
    out = []
    for a, b in zip(points, points[1:]):
        d = tuple(q - p for p, q in zip(a, b))
        centre = tuple(round((p + q) / 2, 3) for p, q in zip(a, b))
        out.append((v3(*centre), up_to(d), round(math.sqrt(sum(c * c for c in d)) / 2, 3)))
    return out


def one_a_frame(keys):
    clean, last = [], -1
    for key in sorted(keys, key=lambda k: k[0]):
        if key[0] > last:
            clean.append(key)
            last = key[0]
    return clean


def crawler(side, rng):
    """An arm's crawls: its line's strokes lit in turn, shoulder to hand or back, then the whole line at once, then a
    gap: the tracks of its strokes."""
    rows = [{"At": [], "Tilt": [], "Foot": [], "Top": [], "Transparency": [[0, 1]]} for _ in range(STROKES)]
    f, down = rng.randint(2, 30), rng.random() < 0.5
    length = (STROKES - 1) * STAGGER + LIT + 1 + SNAP
    while f < SHORT - length - 2:
        order = list(range(STROKES)) if down else list(range(STROKES - 1, -1, -1))
        snap = f + (STROKES - 1) * STAGGER + LIT + 1
        for row, (at, tilt, half) in zip(rows, strokes(zig(rng, side))):
            for key, value in (("At", at), ("Tilt", tilt), ("Foot", -half), ("Top", half)):
                row[key] += [[f, value], [snap + SNAP, value]]
        for turn, s in enumerate(order):
            b = f + turn * STAGGER
            rows[s]["Transparency"] += [[b - 1, 1], [b, 0], [b + LIT - 1, 0.4], [b + LIT, 1]]
        for row in rows:
            row["Transparency"] += [[snap - 1, 1], [snap, 0], [snap + SNAP - 1, 0.2], [snap + SNAP, 1]]
        f = snap + SNAP + 1 + rng.randint(18, 30)  # the gap
        down = not down
    for row in rows:
        row["Transparency"].append([SHORT, 1])
        for key in row:
            row[key] = one_a_frame(row[key])
    return rows


def shock():
    rng = random.Random(77)
    rows = {}
    for part, side in ARMS:
        for k, tracks in enumerate(crawler(side, rng)):
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
                         "Segments": 1, "ZOffset": 0.1, "Brightness": 3},
                "Tracks": tracks,
                "Why": f"{'the hero: ' if k == 2 else ''}a stroke of a jagged line down the arm's outer edge, lit as the crawl passes, then with the whole line",
            }
    return effect("StateShock", "Shock (Storm), worn while it holds: jagged lines crawling along the arms' outline, flickering through the gaps (AR48, Scintilla's grey, research's rule and pass).", rows)


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
    looks = {"StateBurn": burn(), "StateFreeze": freeze(), "FreezeBreak": freeze_break(), "StateShock": shock(), "StateSap": sap()}
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
