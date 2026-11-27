"""AR69's fall, research's pick A ("the break"), as the game's rows: ShadeFall, in place of ShadeBurst's sky lantern.
Scintilla's.

    py tools/fx/ar69_fall.py [out_dir]        (default: build/handoff/ShadeFire/fx; copy to src/shared/Config/EffectRows/)

Feel line (research): the Shade's last hit lands, and its body comes apart into light and embers with a heavy, volumetric
burst (a 3D shape with depth and a direction, never a flat card facing the camera), over in under a second. No gore:
light, embers and smoke only (rule 4).

Research's pick and must-fix (AR69, 2026-11-27, 14:35): the burst sat beside the foe in the target. It's centred on the
Shade's body here, and the body goes inside the ball as it blooms: the ball starts round the body's middle and covers it
LEAD frames later, when the body hides. The Shade comes apart into it, never stands beside it. Written on the target's
clock, where 0 is the moment the body goes; the file counts from LEAD frames before it (the effect's start).

Hero shape: a ball of fire where the body was, swelling to about the body's size in four frames with a white-hot middle,
cooling from orange to deep red and rising into a soft dark puff, gone by 0.6 s. Flame licks rise off its top and a few
thin spikes are thrown along the blow; gold chips (shards of light, never body pieces) fly out with the blow and fall;
a ring of light runs out over the floor.

The hook (Faber's, asked 2026-11-27): on the Down clip's Burst marker (where ShadeBurst plays today), play ShadeFall at
the body's foot, facing along the defeating blow (its -Z the blow's way, from the one who struck it), and hide the body
LEAD frames later (0.067 s), not at the marker; no row rides the body, so the server may take it once it's hidden.

The technique, from the kit: the ball and its rim are the kit's shell (FxShell) in the flame's rise look, alpha-blended,
so its white-hot middle is one additive particle (fx_glow) drawn toward the camera; the licks and spikes are the burn's
soft tapered streak (round 1: an opaque orange body and an added white-gold core, in the kit's fx_beam) along an unseen
guide, foot to tip; sparks of light (fx_streak) drawn out along their flight; the chips are the kit's chips in a flat
light; the puff is soft grey particles, lit by the scene so it darkens at night; the ring is the kit's hoop, a flat
band a little over the floor.

Written at a body of scale 1 (R6, 5 studs, the root 3 over the foot): Area 1, so a Shade's scale scales it.
"""
import math
import random
import sys
from pathlib import Path

from ar69_burn import BEAM_WIDE, CORE, GOLD, ORANGE, RIM, angles, streak
from element_states import compact
from hit_sparks import c3, v3

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "handoff" / "ShadeFire" / "fx"
LEAD = 4  # frames before the Burst marker the ball starts round the body
CENTRE = (0.0, 3.36, 0.0)  # the target's centre: the torso's middle (0.16 over the root) and 0.2 up
MIDDLE = CENTRE  # the ball's: on the body (research's must-fix; the target's sat 0.35 along the blow)
BALL = 2.35  # studs: the ball's radius at its peak (the target's), then 1.22 times it as it cools
SMOKE = ((96, 89, 86), (150, 143, 138))  # the puff's two tones, lit by the scene (the target's day greys)
EASE_OUT, EASE_IN = "Quad Out", "Quad In"


def mix(a, b, u):
    return tuple(round(x + (y - x) * u) for x, y in zip(a, b))


PICTURE = (250, 184, 110)  # fx_rise_Flame.png's mean colour (2026-11-27): the look's own colour, baked in


def on_picture(colour):
    """The Color that brings the flame look to `colour`: a look's Color multiplies its picture, which is already flame
    coloured (B1's coil wears it untinted), so the target's colour is divided by the picture's."""
    return tuple(min(255, round(255 * c / q)) for c, q in zip(colour, PICTURE))


def ball():
    """The ball and its rim: the kit's shell swelling round the body from LEAD frames before the marker."""
    rows = {}
    for name, size, fade, colour, why in (
            ("Ball", 1.0, 0.05, mix(ORANGE, RIM, 0.1),
             "the hero: a ball of fire on the body, swelling round it as it comes apart"),
            ("Rim", 1.14, 0.45, mix(ORANGE, RIM, 0.65), "its outline, deeper and fainter, a little over it")):
        r = [(-LEAD, 0.7 * size), (-1, 1.7 * size), (4, BALL * size), (21, BALL * 1.22 * size)]
        y = MIDDLE[1] + (0.15 if name == "Rim" else 0.0)
        rows[name] = {
            "Kind": "Mesh",
            "From": "Burst",
            "Part": ["FxShell"],
            "Look": "fx_rise_Flame",
            "Tracks": {
                "At": [[-LEAD, v3(MIDDLE[0], y, MIDDLE[2])], [4, v3(MIDDLE[0], y, MIDDLE[2]), EASE_OUT],
                       [24, v3(MIDDLE[0], y + 1.1, MIDDLE[2])]],
                "Scale": [[f, v3(round(k, 3), round(k * 0.95, 3), round(k, 3)), EASE_OUT] for f, k in r],
                # it thins from 0.16 s (research's must-fix 3), near linear as the target's: half gone by 0.27 s
                "Transparency": [[-LEAD, 0.4, EASE_OUT], [-2, fade], [10, fade], [22, 1]],
                # cooling toward the rim's brown-orange, never deep red (the content check of 14:33)
                "Color": [[-LEAD, c3(on_picture(colour))], [5, c3(on_picture(colour))],
                          [19, c3(on_picture(mix(colour, RIM, 0.6)))]],
                # round 1: 2.5 washed the ball to pale yellow under the Heart in the engine (the take, 23:5x)
                "Glow": [[-LEAD, 1.4], [5, 1.4], [19, 0.8]],
            },
            "Why": why,
        }
    return rows


def glow(name, frame, life, sizes, fades, colours, near, why, bright=1):
    """One additive particle of fx_glow at the ball's middle, drawn `near` studs toward the camera, `bright` times its
    colour at its middle."""
    return {
        "Kind": "Emitter",
        "From": "Burst",
        "Image": "fx_glow",
        "Emitter": {
            "Lifetime": [life, life], "Speed": [0.01, 0.01], "LockedToPart": True,
            "Size": sizes, "Transparency": fades, "Color": colours,
            "LightEmission": 1, "LightInfluence": 0, "ZOffset": near, "Brightness": bright,
        },
        "Emit": [[frame, 1]],
        "Tracks": {"At": [[-LEAD, v3(*MIDDLE)]]},
        "Why": why,
    }


def lick(name, frame, foot, d, length, width, grow, hold, gone, why, rise=0.0, bright=1.2):
    """A flame lick off the ball: its guide from the foot along d (unseen), and the flame on it, the burn's streak (its
    body and core, round 1) from foot to tip. It grows over `grow` frames, holds to `hold`, and is gone by `gone`."""
    ax, az = angles(d)
    beam_width = width * BEAM_WIDE
    top = [[frame, 0.05, EASE_OUT], [frame + grow, length], [gone, length * (1 + rise)]]
    guide = {
        "Kind": "Beam",
        "From": "Burst",
        "Image": "fx_beam",
        "Beam": {"Segments": 1},
        "Tracks": {
            "At": foot,
            "Tilt": [[frame, v3(round(ax, 2), 0, round(az, 2))]],
            "Top": top,
            "Width": [[frame, 0]],  # never drawn, and clear: its ends are the flame's
            "Transparency": [[frame, 1]],
        },
        "Why": f"{name}'s guide, unseen: its foot on the ball and its tip",
    }
    widths = [[frame, round(beam_width * 0.4, 3), EASE_OUT], [frame + grow, round(beam_width, 3)],
              [gone, round(beam_width * 0.6, 3)]]
    flame = streak(name, f"{name}Guide", widths, [[frame, 0], [hold, 0, EASE_IN], [gone, 1]], length * (1 + rise), why,
                   bright=bright)
    for row in flame.values():
        row["From"] = "Burst"
    return {f"{name}Guide": guide, **flame}


def blender(x, y, z):
    """The target's Blender vector (z up, y away) in the effect's frame (y up, the blow along -Z)."""
    return (x, z, -y)


def unit(d):
    m = math.sqrt(sum(c * c for c in d))
    return tuple(c / m for c in d)


def licks():
    rows = {}
    rnd = random.Random(17)  # the target's seeds, drawn in its order
    for n in range(6):
        d = unit(blender(rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(0.6, 1.4)))
        d = unit((d[0], d[1], d[2] - rnd.uniform(0.1, 0.5)))  # and along the blow
        length, width, delay = rnd.uniform(1.6, 2.6), rnd.uniform(1.5, 2.1), round(rnd.uniform(1, 3))
        foot = [[delay, v3(*(round(MIDDLE[i] + d[i] * BALL * 0.75, 3) for i in range(3))), EASE_OUT],
                [24, v3(*(round(MIDDLE[i] + d[i] * BALL * 0.9 + (1.1 if i == 1 else 0), 3) for i in range(3)))]]
        rows.update(lick(f"Lick{n + 1}", delay, foot, d, length, width, 5, 10 + delay, 23 + delay,
                         "a flame lick off the ball's top, rising", rise=0.3))
    rnd = random.Random(11)
    for n in range(6):
        a, e = rnd.uniform(-0.9, 0.9), rnd.uniform(-0.2, 0.8)
        d = (math.sin(a) * math.cos(e), math.sin(e), -math.cos(a) * math.cos(e))  # along the blow, spread
        length, delay, width = rnd.uniform(2.4, 3.8), round(rnd.uniform(0, 1.5)), rnd.uniform(0.4, 0.6)
        foot = [[delay, v3(*(round(CENTRE[i] + d[i] * 1.6, 3) for i in range(3))), EASE_OUT],
                [12, v3(*(round(CENTRE[i] + d[i] * 3.6, 3) for i in range(3)))]]
        rows.update(lick(f"Spike{n + 1}", delay, foot, d, length, width, 4, 4 + delay, 11 + delay,
                         "a thin spike of flame thrown along the blow, quick", bright=1.3))
    return rows


def chips():
    """Shards of light flung out with the blow, falling, gold cooling to orange, gone in the air (never body pieces)."""
    rows = {}
    rnd = random.Random(23)
    for n in range(16):
        a, e = rnd.uniform(-1.5, 1.5), rnd.uniform(0.1, 1.0)
        d = (math.sin(a) * math.cos(e), math.sin(e), -math.cos(a) * math.cos(e))
        speed, start = rnd.uniform(9, 17), round(rnd.uniform(0, 2))
        life, size = round(rnd.uniform(0.42, 0.62) * 60), rnd.uniform(0.16, 0.3)
        at, tilt, f = [], [], 0
        spin = (math.degrees(14), math.degrees(9))  # the target's turn, radians a second
        while f <= life:
            tt = f / 60
            drag = (1 - math.exp(-2.2 * tt)) / 2.2
            p = [CENTRE[i] + d[i] * (1.0 + speed * drag) for i in range(3)]
            p[1] -= 11.0 * tt * tt * 0.5
            if p[1] < 0.4:  # it goes out before the floor
                life = f
                break
            at.append([start + f, v3(*(round(c, 3) for c in p))])
            tilt.append([start + f, v3(round(spin[0] * tt + n * 40, 1), 0, round(spin[1] * tt, 1))])
            f += 3
        colour = [[start, c3(CORE)], [start + round(life * 0.3), c3(GOLD)], [start + life, c3(ORANGE)]]
        rows[f"Chip{n + 1}"] = {
            "Kind": "Mesh",
            "From": "Burst",
            "Part": [f"FxChip{n % 3 + 1}"],
            "Tracks": {
                "At": at,
                "Tilt": tilt,
                "Scale": [[start, round(size * 2.6, 3)], [start + life, round(size * 2.6 * 0.6, 3)]],
                "Color": colour,
                "Transparency": [[start, 0], [start + round(life * 0.55), 0, EASE_IN], [start + life, 1]],
            },
            "Why": "a chip of light flung out with the blow, falling, cooling" if n else
                   "the chips: shards of light flung out with the blow, falling and cooling, gone in the air",
        }
    return rows


def puff(tone, near, why):
    """Soft lumps rising off the top as the fire goes (the target's five, 0.14 s to 0.24 s, 0.55 s each), lit by the
    scene: grey by day, dark at night."""
    return {
        "Kind": "Emitter",
        "From": "Burst",
        "Image": "fx_glow",
        "Emitter": {
            "Lifetime": [0.5, 0.6], "Speed": [7, 9], "EmissionDirection": "Top", "SpreadAngle": [20, 20], "Drag": 2,
            "Rotation": [0, 360],
            "Size": [[0, 1.6], [0.4, 3.2], [1, 4.0]],
            "Transparency": [[0, 1], [0.1, 0.15], [0.5, 0.45], [1, 1]],
            "Color": [[0, c3(tone)], [1, c3(tone)]],
            "LightEmission": 0, "LightInfluence": 1, "ZOffset": near,
        },
        "Emit": [[8, 1], [10, 1], [11, 1], [13, 1], [14, 1]],
        "Tracks": {"At": [[8, v3(CENTRE[0], CENTRE[1] + 1.6, CENTRE[2] - 0.4)]], "Radius": [[8, 1.0]]},
        "Why": why,
    }


def ring():
    """The kit's hoop as a flat band of light on the floor. Round 1 (research's must-fix 2): a Ground row is set down to
    the foot exactly, so the hoop's floor band lay in the floor and only its lip showed, a thin gold line in the engine;
    it stands on its At now, a little over the floor. The band is the hoop's own, 0.3 of its radius: 0.3 to 1.0 studs
    while it's bright (to 0.2 s), to 1.5 as it fades (the target's 0.55 to 1.1, to 1.45). Its run and fade are the target's: out
    with an ease near Cubic Out over 0.35 s, its fade u^1.5 in two straight pieces."""
    return {
        "Kind": "Mesh",
        "From": "Burst",
        "Part": ["FxHoop"],
        "Color": c3(GOLD),
        "Tint": True,  # a typed Shade's colour in place of the gold (the Hard Shade's Shades.Hard.Burst), the fire untinted
        "Tracks": {
            "At": [[1, v3(0, 0.06, 0)]],
            "Scale": [[1, v3(1.0, 0.3, 1.0), "Cubic Out"], [22, v3(6.5, 0.3, 6.5)]],
            "Transparency": [[1, 0], [11, 0.35], [22, 1]],
        },
        "Why": "a ring of light running out over the floor",
    }


def sparks():
    """Gemini's stretched sparks (research, round 1): a burst of thin streaks of light thrown along the blow, drawn out
    along their flight, slowing and falling, gone in a quarter second."""
    return {
        "Kind": "Emitter",
        "From": "Burst",
        "Image": "fx_streak",
        "Emitter": {
            "EmissionDirection": "Front",  # the effect's Front (-Z) is the blow
            "SpreadAngle": [70, 45],
            "Lifetime": [0.16, 0.3],
            "Speed": [22, 34],
            "Drag": 5,
            "Acceleration": v3(0, -14, 0),
            "Orientation": "VelocityParallel",
            "Size": [[0, 0.32], [0.6, 0.24], [1, 0]],
            "Squash": [[0, -1.6], [1, -0.7]],  # drawn out along their flight, less as they slow
            "Transparency": [[0, 0], [0.6, 0.1], [1, 1]],
            "Color": [[0, c3(CORE)], [0.4, c3(GOLD)], [1, c3(ORANGE)]],
            "LightEmission": 1,
            "LightInfluence": 0,
            "Brightness": 2,
            "ZOffset": 0.4,
        },
        "Emit": [[0, 18]],
        "Tracks": {"At": [[-LEAD, v3(*CENTRE)]]},
        "Why": "sparks of light thrown along the blow as the body goes, drawn out along their flight",
    }


def light():
    return {
        "Kind": "Light",
        "From": "Burst",
        "Color": c3(ORANGE),
        "Range": 16,
        "Tracks": {"At": [[-LEAD, v3(CENTRE[0], CENTRE[1] + 0.4, CENTRE[2])]],
                   "Brightness": [[-LEAD, 0, EASE_OUT], [3, 5], [5, 5, EASE_IN], [30, 0.4], [31, 0]]},
        "Why": "its light on the floor and the fighters round it",
    }


def fall():
    rows = {}
    rows.update(ball())
    rows["Heart"] = glow("Heart", -2, 0.25, [[0, 4.2], [1, 2.8]], [[0, 0], [0.3, 0.1], [1, 1]],
                         [[0, c3(CORE)], [1, c3(GOLD)]], 2.8, "its white-hot middle, added light before the ball",
                         bright=2.4)  # the target's heart, 2.4 times its colour (ar69_targets.py, fall_a)
    rows["Flash"] = glow("Flash", 0, 0.1, [[0, 6.6], [1, 7.2]], [[0, 0.3], [1, 1]], [[0, c3(CORE)], [1, c3(CORE)]],
                         3.0, "one flash as the body goes")
    rows.update(licks())
    rows.update(chips())
    rows["PuffDark"] = puff(SMOKE[0], -0.3, "the puff's shade, under it")
    rows["Puff"] = puff(SMOKE[1], 0, "the puff: soft grey lumps rising off the top as the fire goes")
    rows["Ring"] = ring()
    rows["Sparks"] = sparks()
    rows["Light"] = light()
    for name, row in rows.items():
        del row["From"]  # no action: its frames count from the effect's start, LEAD before the body goes
        if name.endswith("Guide"):
            row["Tracks"]["Foot"] = [[row["Tracks"]["At"][0][0], 0]]  # its foot at its At
        for keys in row["Tracks"].values():
            for key in keys:
                key[0] += LEAD
                if len(key) == 3 and key[2] is None:  # a key's ease left out where it's Linear
                    key.pop()
        for emit in row.get("Emit", []):
            emit[0] += LEAD
        for keys in row["Tracks"].values():
            assert keys[0][0] >= 0, name
    return {"Schema": "rows/1", "Effect": "ShadeFall",
            "Why": "A Shade falls: its body comes apart into a ball of fire where it stood, licks and spikes, chips of "
                   "light and a puff, a ring on the floor (AR69, research's pick A, for ShadeBurst's lantern).",
            "Area": 1, "Grey": False, "Rows": rows}


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else OUT
    out.mkdir(parents=True, exist_ok=True)
    data = fall()
    path = out / "ShadeFall.rows.json"
    path.write_bytes((compact(data) + "\n").encode("utf-8"))
    keys = sum(len(k) for r in data["Rows"].values() for k in r["Tracks"].values())
    print(f"wrote {path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else path}: "
          f"{len(data['Rows'])} rows, {keys} keys, {path.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
