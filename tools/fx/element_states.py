"""The element states' looks (AR48), in colour past research's grey pass, as rows files for tools/fx/rows_take.py. Scintilla's.

    py tools/fx/element_states.py [out_dir]        (default: build/handoff/States/fx)
    py tools/fx/element_states.py --pictures       (fx_mote_rim, Sap's mote, into build/handoff/States/pictures)

The looks research picked are Modulo's block-in (tools/blender/element_states_fx.py, `Cues` and `Ice`); these are the
same timings and shapes in the game's rows, from the kit only. FighterController wears each by name while its state
holds (StateBurn, StateSap; a freeze is the stun's StateFreeze; a chill and a shock wear none) and ends it at once,
so every row rides the body and holds to a far frame. FreezeBreak is the one free effect: the shell's shatter as the
freeze ends, played where the body stands.

Feel line: a Frost lead's third hit lands, a shell of ice snaps shut round the Shade and bursts into chips; a Fire hit
leaves embers rising off its head and shoulders, a Storm hit light crawling along its arms, a Void hit dark motes drawn
out of it. Quieter than a hit, never hiding the silhouette.

Research's rule for a state (AR48's pass in motion, 2026-11-26): it sits on the body's outline, shows in the gaps between
hits, and takes a shape no hit uses (a hit is a white star, a ring and radial sparks). Nothing at the feet: at the
player's camera the body hides the floor.

Hero shapes (one each, with a direction and an acceleration):
- Burn: AR69 replaced its embers with flame tongues, written by tools/fx/ar69_burn.py (git log has this file's).
- Chill: no look. Research's pass of 2026-11-26 dropped its crust on the legs (the lead hides them at the player's
  camera): Freeze carries Frost alone, and a chill keeps its slow and its numbers.
- Freeze: a shell snapping up from the street and shut in 6 frames, its edge flashing once, held clear. Stand-in: the
  kit's shell in its ribs (the faceted shell waits on its mesh). FreezeBreak: a few hand-sized shards bursting out
  at the body's height over 8 frames, in the hit spark's place (research's must-fix, 2026-11-26).
- Shock: no look. Research's pass of 2026-11-26, 21:17: a crawling line on the arms missed twice at a phone's scale,
  and a shock does nothing until poise; its look starts from a new target then (git log has this file's line).
- Sap: motes drawn out of the body, each a dark disc with a thin light rim (the rim carries the read), born just
  outside the arms' outline at the chest and drifting slowly outward and a little up, slowing, fading where they are:
  never sinking, speeding up or stretching (a dark drop running down a body reads as a drip, in a still frame too; the
  content check of 2026-11-26 blocked research's falling for it). Its violet stays a rim. Spread, each spot about one
  mote at a time and its own size: a cluster of small dark dots reads as holes (research's must-fix, 2026-11-26).

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

FROST = ((244, 253, 255), (143, 227, 255))
SAP_RIM = (211, 186, 255)  # Sap's rim, its disc dark in the picture: Void's violet (#B58CFF) lifted toward white to the
# grey pass's value (about 200 of 255), so the rim reads on the dark robe as it did in grey; the violet only this rim

START_H = 2.25  # studs: the shell's height as it starts, at the hips
SHELL_W, SHELL_D, SHELL_H = 2.35, 1.3, 5.35  # the shell's half width, half depth, height
SHUT = 6  # frames: the shell snaps shut (0.1 s)
ROOT_HEIGHT = 3  # studs: the root over the foot, at scale 1


COLOURED = {"StateFreeze", "FreezeBreak", "StateSap"}  # past research's grey pass, in their colour (2026-11-26)


def effect(name, why, rows):
    return {"Schema": "rows/1", "Effect": name, "Why": why, "Area": 1, "Grey": name not in COLOURED, "Rows": rows}


def held(value):
    return [[0, value], [FAR, value]]


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
            "Transparency": [[0, 0.3, "Quad Out"], [SHUT + 2, 0.45], [FAR, 0.45]],  # held clear, the body showing through; at 0.55 its blue read grey
            "Glow": [[0, 1.5, "Linear"], [SHUT, 1.5, "Linear"], [SHUT + 1, 4, "Quad Out"], [SHUT + 3, 1.2], [FAR, 1.2]],  # its edge flashes once
        },
        "Why": "the hero: a shell of ice snapping up out of the frost and shut round the body",
    }
    return effect("StateFreeze", "Freeze (Frost), the stun's look: the shell shut round the body (AR48, Scintilla's grey).", {"Shell": shell})


SHARDS = 6  # a few (research's must-fix, 2026-11-26, 21:4x)
BURST = 8  # frames: the shards burst out and are gone (research: 6 to 8)
SHARD = (1.3, 6.0, 3.0)  # the chip mesh (1 x 0.14 x 0.35, a sliver) scaled to a chunk about the foe's hand: 1.3 x 0.86 x 1.05,
# thick enough that no view shows it edge-on (at 0.45 thick, flat, the camera saw slivers: 21:50)


def freeze_break():
    """The shell bursting into a few hand-sized shards, out from the body at its height over 8 frames, then gone: in
    the hit spark's place on the hit that breaks it (FighterController's call), never flecks falling to the feet."""
    rng = random.Random(48)
    rows = {}
    for k in range(SHARDS):
        a = 2 * math.pi * (k + rng.uniform(-0.25, 0.25)) / SHARDS
        out = (math.cos(a), math.sin(a))
        h = rng.uniform(0.35, 0.8) * SHELL_H  # the body's height, chest to head
        p0 = (out[0] * SHELL_W * 0.6, h, out[1] * SHELL_D * 0.6)
        far = rng.uniform(1.6, 2.2)  # studs out over the burst
        rise = rng.uniform(-0.15, 0.35)
        p1 = (p0[0] + out[0] * far, h + rise, p0[2] + out[1] * far)
        start = [rng.uniform(-180, 180) for _ in range(3)]  # tumbling, so each shows a face as it flies
        spin = [rng.choice((-1, 1)) * rng.uniform(90, 150) for _ in range(3)]
        s = rng.uniform(0.85, 1.15)
        size = v3(*(round(c * s, 3) for c in SHARD))
        rows[f"Shard{k + 1}"] = {
            "Kind": "Mesh",
            "Part": [f"FxChip{k % 3 + 1}"],
            "Color": c3(FROST[1]),
            "Tracks": {
                "At": [[0, v3(*(round(c, 3) for c in p0)), "Quart Out"], [BURST, v3(*(round(c, 3) for c in p1))]],
                "Tilt": [[0, v3(*(round(a, 1) for a in start)), "Quad Out"], [BURST, v3(*(round(a + b, 1) for a, b in zip(start, spin)))]],
                "Scale": [[0, size, "Quad In"], [BURST, v3(*(round(c * 0.75, 3) for c in (size["Vector3"])))]],
                "Transparency": [[0, 0], [4, 0, "Quad In"], [BURST, 1]],
                "Glow": [[0, 3, "Quad Out"], [BURST, 1]],
            },
            "Why": "the hero: a shard of the shell, about the foe's hand, bursting out at the body's height" if k == 0 else "the next shard, round the body",
        }
    return effect("FreezeBreak", "The freeze's end: the shell bursts into a few hand-sized shards at the body's height, in the hit spark's place (AR48, research's must-fix).", rows)


# Sap -------------------------------------------------------------------------------------------------------------
RING = 2.25  # studs out from the body's middle, each side: just past the arms' outer faces (2)
# each side's spots, (z, height over the root, the mote's size): spread over the chest's height and its depth, each its
# own size, so the motes never bunch into a cluster (research's must-fix, 2026-11-26: never more than two touching)
# 0.9 apart in height, so two spots' motes never stack into three at the shoulder (the take of 21:47 did, at 0.5)
SPOTS = ((-0.6, 1.4, 0.22), (0.1, -0.4, 0.42), (0.65, 0.5, 0.3))
SAP_RATE = 0.45  # motes a second a spot: about one out at a time, gone before the next is near it


def sap():
    rows = {}
    for name, side in (("Left", -1), ("Right", 1)):
        for k, (z, y, size) in enumerate(SPOTS):
            rows[f"Motes{name}{k + 1}"] = {
                "Kind": "Emitter",
                "Body": "HumanoidRootPart",
                "Image": "fx_mote_rim",
                "Emitter": {
                    "LockedToPart": True,  # going with the body
                    "Lifetime": [1.6, 2.2],
                    "EmissionDirection": "Left" if side < 0 else "Right",  # out, away from the body
                    "SpreadAngle": [30, 30],
                    "Speed": [1.4, 1.8],  # each leaves its birth spot (about a stud out) before the next is born
                    "Drag": 1.3,
                    "Acceleration": v3(0, 0.25, 0),  # slowing as they leave, a little lift: never a sink (the content check)
                    "Size": [[0, 0], [0.1, size], [0.75, size], [1, 0]],
                    "Transparency": [[0, 0], [1, 0]],
                    "Color": c3(SAP_RIM),
                    "LightEmission": 0,
                    "LightInfluence": 0,
                    "ZOffset": 0.2,
                },
                "Emit": [[0, 1]],
                "Tracks": {"At": held(v3(RING * side, y, z)), "Radius": held(0.2), "Rate": held(SAP_RATE)},
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
    looks = {"StateFreeze": freeze(), "FreezeBreak": freeze_break(), "StateSap": sap()}
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
