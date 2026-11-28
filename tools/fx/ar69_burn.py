"""AR69's burn, research's pick A ("the tongues"), installed in the game's rows. Scintilla's.

    py tools/fx/ar69_burn.py [out_dir]        (default: build/handoff/ShadeFire/fx; copy to src/shared/Config/EffectRows/)
    py tools/fx/ar69_burn.py --pictures       (fx_lick_Flame, fx_lick_Soft, fx_lick_Core into build/handoff/ShadeFire/pictures)

Feel line (research): a burning foe carries real flame on its body, licking up from it in 3D and moving with it,
readable at the player's camera against day and night.

Research's pick and must-fix (AR69, 2026-11-27, 14:35): eight tongues on the shoulders, the arms' backs, the back and
the hips, never the head or neck. The target's strip barely changed and its tongues read as rigid orange crystal spikes:
each tongue's height and lean now flicker on its own beat, with a tip that curls and breaks into embers, held to the
body's sides as the game's camera sees them.

Hero shape: a flame tongue, wide and round at its foot on the body, narrowing as it rises and leans back and out, its
tip curling to one side and breaking off in two pieces, embers rising off it. Its life is a lick, again and again on
its own beat: it stretches up and thins, then sinks and swells, while its lean sways on a slower beat of its own.

The technique (round 2, 2026-11-28): each tongue is two Beams facing the camera (so it reads as flame from every side),
along an unseen guide that carries its lick and its sway, drawn from the guide's tip down to its foot. The tongue's shape
is in their pictures' alpha: fx_lick_Soft, a round foot, widest a quarter up, a tapered tip, soft-edged with no outline,
for an opaque orange body (laid over, so it holds by day); fx_lick_Core, narrower and shorter inside it, for an added
white-gold core, the tip left orange. Each tongue arcs along its guide's X (the ends take the guide's turn since
Faber's aa6b147f): straight off its foot, its tip curling out the way it leans or back over the body (CURLS). Round 0's
fx_lick_Flame (the target's fire drawn with its outline) read as flat cut-outs, and round 1's fx_beam streaks (the
shape from a straight taper) as rigid spikes, a cone round a white needle; the fall's licks and spikes keep round 1's
streak (streak(), below), which suits their thin rays. A row of embers rides each tongue's tip (On its guide: they lean
with it). A warm light flickers on the body.

Written at a body of scale 1 (R6, 5 studs, the root 3 over the foot): Area 1, so a foe's scale scales it. The tongues'
places are the target's, measured on the Brawler at scale 1 from the torso's middle, 0.16 over the root.

Every track holds to FAR, as each state's look does (tools/fx/element_states.py): FighterController ends the look when
its burn ends. The keys are each lick's top and bottom, eased between, so a burn of a minute stays a few thousand keys.
"""
import json
import math
import random
import subprocess
import sys
from pathlib import Path

import numpy as np

from element_states import compact
from hit_sparks import c3, v3

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "handoff" / "ShadeFire" / "fx"
PICTURES = ROOT / "build" / "handoff" / "ShadeFire" / "pictures"
FAR = 3600  # frames: a look holds to here (element_states.FAR)
TORSO_UP = 0.16  # studs: the Brawler's torso middle over its root, at scale 1 (AR69's pose, 13:43)
EASE = "Sine InOut"

# the target's fire, in sRGB (ar69_targets.py's CORE, GOLD, ORANGE, RIM, linear there)
CORE = (255, 246, 219)
GOLD = (255, 197, 84)
ORANGE = (255, 140, 60)
RIM = (186, 77, 25)

# The tongues, as the target placed them (ar69_targets.TONGUES): where each stands in the torso's own space (X its
# right, Y up, Z its back), its lean there, its length and width (studs at scale 1), its lick's beat (s) and phase.
TONGUES = [
    ("FarShoulder", (-1.7, 1.0, 0.1), (-0.35, 1.0, 0.25), 3.2, 1.6, 0.47, 0.0),
    ("NearShoulder", (1.7, 1.0, 0.15), (0.35, 1.0, 0.25), 3.0, 1.55, 0.53, 0.6),
    ("FarArm", (-1.9, -0.3, 0.4), (-0.3, 1.0, 0.3), 2.5, 1.3, 0.39, 0.3),
    ("NearArm", (1.9, -0.4, 0.4), (0.3, 1.0, 0.3), 2.4, 1.25, 0.36, 0.45),
    ("Back", (-0.6, 0.3, 0.85), (-0.05, 1.0, 0.45), 3.1, 1.5, 0.43, 0.8),
    ("BackLow", (0.6, -0.5, 0.85), (0.05, 1.0, 0.45), 2.6, 1.35, 0.58, 0.15),
    ("Hips", (0.0, -1.3, 0.7), (0.0, 1.0, 0.5), 2.2, 1.2, 0.41, 0.55),
    ("NearHip", (1.2, -1.6, 0.2), (0.25, 1.0, 0.2), 1.8, 1.0, 0.33, 0.9),
]
DRAWN = 0.72  # the picture's tongue at its widest, a share of the beam's width (HALF below, twice)
SHOWN = 0.83  # the target's tongue at its widest, a share of its `width` (tongue_width at a quarter up)
LICK = (0.66, 1.12)  # a lick's height, low and high, a share of the tongue's length (the target's 0.79 to 1.09, wider:
# research's must-fix, the target's barely moved)
SWAY = (7, 15)  # degrees each way the lean sways sideways, a beat 1.4 times the lick's
NOD = 6  # degrees back and forth on the sway's beat
EMBERS = 0.8  # where on the tongue its embers start, a share of its length


def angles(d):
    """Degrees (X, 0, Z) that turn up into the direction d, as Rows applies a Tilt: Angles(X, Y, Z) on up."""
    x, y, z = d
    n = math.sqrt(x * x + y * y + z * z)
    x, y, z = x / n, y / n, z / n
    return math.degrees(math.atan2(z, y)), math.degrees(-math.asin(x))


def lick_keys(rng, beat, phase, length, width):
    """Top and Width keys: each lick's bottom and top, with each beat and height a little its own."""
    top, wide = [], []
    t = -phase * beat * 60
    low = True
    while t < FAR:
        size = rng.uniform(LICK[0], LICK[0] + 0.1) if low else rng.uniform(LICK[1] - 0.12, LICK[1])
        frame = max(0, round(t))
        if not top or frame > top[-1][0]:
            top.append([frame, round(length * size, 3), EASE])
            # taller is thinner: a lick stretches up and thins, then sinks and swells
            wide.append([frame, round(width * (1.25 - 0.4 * size), 3), EASE])
        span = beat * 60 * rng.uniform(0.85, 1.15)
        t += span * (0.55 if low else 0.45)  # it rises slower than it sinks
        low = not low
    return top, wide


def sway_keys(rng, beat, base):
    ax, az = base
    keys = []
    t = 0
    side = rng.choice((-1, 1))
    while t < FAR:
        keys.append([round(t), v3(round(ax + rng.uniform(-NOD, NOD), 2), 0, round(az + side * rng.uniform(*SWAY), 2)), EASE])
        t += beat * 60 * 1.4 * rng.uniform(0.8, 1.2) / 2
        side = -side
    return keys


# Round 1 on research's cause (Quaestor, 2026-11-27: the outlined picture reads as paper cut-outs; the engine take
# agreed): every flame is a soft tapered streak in the kit's fx_beam (soft across, solid along), two layers on its
# guide from foot to tip, its shape from its widths: wide at the foot, fading into the body there, to a point.
BODY = (244, 108, 36)  # the streak's body, laid over (LightEmission 0.15): the orange that holds by day on a light floor
HEAT = (255, 224, 150)  # its core, added light: white-gold, hottest low, the tip left orange
BEAM_WIDE = 1.3  # a streak's beam width over the flame's: fx_beam shows about three quarters, and it tapers
CORE_WIDE = 0.4  # the core's width, a share of the body's
TAPER = 0.06  # the tip's width, a share of the foot's: near a point
CORE_REACH = 0.72  # how far up the core runs, a share of the length
FOOT_FADE = 0.22  # the foot's fade into the body, a share of the flame's length at its tallest


def streak(name, guide, widths, fades, length, why, bright=1.1, taper=TAPER):
    """Two rows on `guide` (a beam row, unseen, whose ends are the flame's foot and tip): the body and its core."""
    first = widths[0][0]
    base = {"Kind": "Beam", "On": guide,  # it rides the body through its guide: its scale, and gone with it
            "Low": f"{guide}.Low", "High": f"{guide}.High", "Image": "fx_beam",
            "FootFade": round(length * FOOT_FADE, 3)}
    look = {"FaceCamera": True, "LightInfluence": 0, "TextureMode": "Stretch", "TextureLength": 1,
            "TextureSpeed": 0, "Segments": 1}
    body = dict(base, Taper=taper, Color=c3(BODY),
                Beam=dict(look, LightEmission=0.15, Brightness=bright),
                Tracks={"Width": widths, "Transparency": fades}, Why=why)
    core = dict(base, Taper=round(min(1, taper * 2), 3), Color=c3(HEAT),
                Beam=dict(look, LightEmission=1, Brightness=round(bright * 1.8, 2), ZOffset=0.05),
                Tracks={"Width": [[k[0], round(k[1] * CORE_WIDE, 3)] + k[2:] for k in widths], "Transparency": fades,
                        "Reach": [[first, CORE_REACH]]},
                Why=f"{name}'s core: added white-gold heat down its middle, short of its tip")
    return {name: body, f"{name}Core": core}


# Round 2 on research's three causes (Quaestor, 2026-11-28, 00:2x: round 1's streaks read as rigid spikes, a cone round a
# white needle): the tongue's shape is in its pictures' alpha along their length, a round foot, widest a quarter up and
# a tapered tip, with no outline; the body and its core are as wide as each other, the core's own picture narrower and
# shorter inside the body's. Each is drawn from its guide's tip down to its foot, its picture stored tip-up (the
# content check of 2026-11-27, 17:00). Each tongue's own curve waits on Faber's turn of the beam's ends (AR69).
CURL = 0.24  # each tongue's CurveSize0, a share of its length: its arc and its tip's curl
# which way each tongue curls: 1 out the way it leans, -1 back over the body. Never a matching pair on the shoulders:
# curled out alike, the two read as horns from the front at 64 px (the offline model, 2026-11-28, 00:5x)
CURLS = {"FarShoulder": 1, "NearShoulder": -1, "FarArm": -1, "NearArm": 1, "Back": 1, "BackLow": -1, "Hips": 1,
         "NearHip": -1}
SOFT_WIDE = 1.3 * SHOWN / DRAWN  # the beam's width over the flame's `width`; its soft edge eats about a third of it  # the beam's width over the flame's `width`: the pictures' tongue is DRAWN of it at its widest


def soft_streak(name, guide, widths, fades, why, bright=1.1, curve=None):
    """Two rows on `guide` (a beam row, unseen, whose ends are the flame's foot and tip), from its tip down to its
    foot: the body and its core, their shapes their pictures'."""
    base = {"Kind": "Beam", "On": guide,  # it rides the body through its guide: its scale, and gone with it
            "Low": f"{guide}.High", "High": f"{guide}.Low"}  # the picture's top row, its tip, at the guide's tip
    look = {"FaceCamera": True, "LightInfluence": 0, "TextureMode": "Stretch", "TextureLength": 1, "TextureSpeed": 0}
    if curve:  # along the guide's own X: its ends take its turn (Rows.luau, Faber's aa6b147f)
        look["CurveSize0"], look["CurveSize1"] = curve
    body = dict(base, Image="fx_lick_Soft", Color=c3(BODY), Beam=dict(look, LightEmission=0.15, Brightness=bright),
                Tracks={"Width": widths, "Transparency": fades}, Why=why)
    core = dict(base, Image="fx_lick_Core", Color=c3(HEAT),
                Beam=dict(look, LightEmission=1, Brightness=round(bright * 1.8, 2), ZOffset=0.05),
                Tracks={"Width": widths, "Transparency": fades},
                Why=f"{name}'s core: added white-gold heat up its lower part, the tip left orange (its picture's)")
    return {name: body, f"{name}Core": core}


def tongue(name, at, lean, length, width, beat, phase, seed):
    """The guide, unseen, from the foot up to the tip, carrying the lick and the sway; and the flame on it, a soft
    tongue (its body and core) from the guide's tip down to its foot."""
    rng = random.Random(seed)
    foot = v3(at[0], round(at[1] + TORSO_UP, 3), at[2])
    top, wide = lick_keys(rng, beat, phase, length, width * SOFT_WIDE)
    guide = {
        "Kind": "Beam",
        "Body": "HumanoidRootPart",
        "Image": "fx_beam",
        "Beam": {"Segments": 1},
        "Tracks": {
            "At": [[0, foot], [FAR, foot]],
            "Tilt": sway_keys(rng, beat, angles(lean)),
            "Top": top,
            "Width": [[0, 0], [FAR, 0]],  # never drawn (and clear, the content check's condition): its ends are the flame's
            "Transparency": [[0, 1], [FAR, 1]],
        },
        "Why": f"{name}'s guide, unseen: the tongue's foot on the body and its tip, licking on its own beat ({beat} s), "
               "its lean swaying on a slower one",
    }
    # its curve along the guide's X (about the body's side), the ends square to the tongue: CurveSize0 alone, at the tip's
    # end (its Low, the guide's tip), so it rises straight off its foot, arcs out the way it leans and curls at its tip.
    # A CurveSize1 would leave the foot sideways too, a zigzag with a bar at its foot (the offline model, 00:5x).
    out = (-1 if lean[0] < 0 else 1) * CURLS[name]
    bend = (round(out * CURL * length * rng.uniform(0.85, 1.15), 2), 0)
    flame = soft_streak(name, f"{name}Guide", wide, [[0, 1, "Quad Out"], [6, 0], [FAR, 0]],
                        f"the hero: a flame tongue, {name}, licking up from a round foot, curling; taller is thinner",
                        curve=bend)
    return guide, flame


def embers(name, length):
    return {
        "Kind": "Emitter",
        "On": name,
        "Image": "fx_ember",
        "Emitter": {
            "FlipbookLayout": "Grid2x2",  # one blob an ember (the kit's note)
            "FlipbookMode": "Loop",
            "FlipbookStartRandom": True,
            "FlipbookFramerate": [0, 0],
            "EmissionDirection": "Top",  # off the tip, along the tongue
            "SpreadAngle": [25, 25],
            "Lifetime": [0.5, 0.8],
            "Speed": [1.5, 3.0],
            "Drag": 1.5,
            "Acceleration": v3(0, 4.5, 0),  # then they rise
            "Orientation": "VelocityParallel",
            "Size": [[0, 0.3], [0.15, 0.5], [0.7, 0.35], [1, 0]],
            "Squash": [[0, -1.0], [1, -0.3]],
            "Transparency": [[0, 0.1], [0.5, 0.1], [0.65, 0.35], [0.75, 0.15], [1, 1]],
            "Color": [[0, c3(CORE)], [0.3, c3(GOLD)], [1, c3(ORANGE)]],
            "LightEmission": 0.3,
            "LightInfluence": 0,
            "Brightness": 1.6,
            "ZOffset": 0.2,
        },
        "Emit": [[0, 1]],
        "Tracks": {"At": [[0, v3(0, round(length * EMBERS, 3), 0)], [FAR, v3(0, round(length * EMBERS, 3), 0)]],
                   "Radius": [[0, 0.25], [FAR, 0.25]], "Rate": [[0, 2.5], [FAR, 2.5]]},
        "Why": f"its tip breaking into embers, on {name}, leaning with it",
    }


def light():
    rng = random.Random(9)
    keys, t = [], 0
    while t < FAR:
        keys.append([t, round(rng.uniform(1.1, 1.9), 2), EASE])
        t += rng.randint(4, 9)
    return {
        "Kind": "Light",
        "Body": "HumanoidRootPart",
        "Color": c3(ORANGE),
        "Range": 9,
        "Tracks": {"At": [[0, v3(0, 1.4, 0.6)], [FAR, v3(0, 1.4, 0.6)]], "Brightness": keys},
        "Why": "the fire's light on the body and the street round it, flickering",
    }


def burn():
    rows = {}
    for n, (name, at, lean, length, width, beat, phase) in enumerate(TONGUES):
        guide, flame = tongue(name, at, lean, length, width, beat, phase, 70 + n)
        rows[f"{name}Guide"] = guide
        rows.update(flame)
        rows[f"{name}Embers"] = embers(f"{name}Guide", length)
    rows["Light"] = light()
    return {"Schema": "rows/1", "Effect": "StateBurn",
            "Why": "Burn (Fire), worn while it holds: flame tongues licking off the shoulders, the arms, the back and the "
                   "hips, each on its own beat, their tips breaking into embers (AR69, research's pick A).",
            "Area": 1, "Grey": False, "Rows": rows}


# The picture ----------------------------------------------------------------------------------------------------
W, H, SS = 128, 256, 4  # the picture (across, along; stored tip-up, the top row its tip) and its supersampling
HALF = DRAWN / 2  # the tongue's half width at its widest, a share of the picture's width
CURL = 0.26  # how far the centre line sweeps sideways at the tip
LEAN = 0.07  # and the other way low down, so it reads as an S, a flame's, never a blade's straight edge
TIP = 0.8  # where the tongue's own point is; past it, two pieces break off along the curl
# the layers, outermost first: their colour, their width and their length as shares of the tongue's (a flame inside a
# flame: the white core short at the foot, the gold to two thirds, the orange to the tip, the rim a thin edge)
LAYERS = ((RIM, 1.0, 1.0), (ORANGE, 0.84, 0.95), (GOLD, 0.6, 0.72), (CORE, 0.3, 0.46))
PIECES = ((0.81, 0.9, 0.4), (0.92, 0.975, 0.24))  # the broken-off pieces: from, to (along), width (of the tongue's)


def smooth(a, b, x):
    k = np.clip((x - a) / (b - a), 0, 1)
    return k * k * (3 - 2 * k)


def lick_picture():
    u = (np.arange(W * SS) + 0.5) / (W * SS)
    v = (np.arange(H * SS) + 0.5) / (H * SS)
    u, v = np.meshgrid(u, v)  # rows along v: row 0, the image's top, is the foot
    centre = 0.5 - LEAN * np.sin(np.clip(v / 0.5, 0, 1) * math.pi) * 0.5 + CURL * smooth(0.35, 1.0, v) ** 1.5 - 0.06

    def shape(v0, v1, width, foot=0.62):
        """d: 0 on the centre line to 1 at the edge, of a tongue from v0 (its foot, `foot` of its widest: a piece's is
        round, from 0) to v1 (its point)."""
        s = (v - v0) / (v1 - v0)
        grow = foot + (1 - foot) * np.sin(np.clip(s / 0.3, 0, 1) * math.pi / 2) ** (0.5 if foot == 0 else 1)
        half = HALF * width * grow * np.clip(1 - s, 0, 1) ** 0.85
        # licks along each edge, each side its own: notches that make the outline flame, not a blade
        left = u < centre
        notch = np.where(left, np.clip(np.sin(2 * math.pi * (v * 3.1 + 0.15)), 0, 1),
                         np.clip(np.sin(2 * math.pi * (v * 2.6 + 0.55)), 0, 1)) ** 3 * smooth(0.25, 0.5, v)
        half = half * (1 - 0.22 * notch)
        d = np.abs(u - centre) / np.maximum(half, 1e-5)
        return np.where((s >= 0) & (s <= 1), d, np.inf)

    rgb = np.zeros(u.shape + (3,), dtype=np.float32)
    rgb[:] = np.array(RIM, dtype=np.float32) / 255  # the edge's own colour under the clear, so the edge never darkens
    alpha = np.zeros(u.shape, dtype=np.float32)
    for colour, width, length in LAYERS:
        inside = shape(0, TIP * length, width) < 1
        rgb[inside] = np.array(colour, dtype=np.float32) / 255
        alpha[inside] = 1
    for v0, v1, width in PIECES:
        for colour, w, length in LAYERS[:3]:
            inside = shape(v0, v0 + (v1 - v0) * length, width * w, 0) < 1
            rgb[inside] = np.array(colour, dtype=np.float32) / 255
            alpha[inside] = 1
    alpha *= smooth(0.0, 0.07, v)  # it grows out of the body
    img = np.concatenate([rgb, alpha[..., None]], axis=-1)
    return img.reshape(H, SS, W, SS, 4).mean(axis=(1, 3))[::-1]  # stored tip-up: the tip on the top row


# Round 2's pictures: white (each row's Color tints it), the shape in the alpha, the edge soft, no outline. Each: its
# half width at its widest (a share of the picture's width), where it's widest and where its point is (shares of the
# length from the foot), where its round foot starts (a share of the length below the picture's bottom row, so the
# soft edge goes round it), and where its soft edge starts (a share of its half width): the body's soft over its outer
# half, the core all soft.
SOFT = {"fx_lick_Soft": (DRAWN / 2, 0.25, 1.0, 0.0, 0.45),
        "fx_lick_Core": (DRAWN / 2 * 0.42, 0.2, 0.7, 0.0, 0.15)}


def soft_picture(name):
    half_max, widest, point, below, edge = SOFT[name]
    u = (np.arange(W * SS) + 0.5) / (W * SS)
    s = (np.arange(H * SS) + 0.5) / (H * SS)
    u, s = np.meshgrid(u, s)  # rows along s from the foot; flipped to tip-up at the end
    k = np.clip((s + below) / (widest + below), 0, 1)
    grow = np.sqrt(np.clip(1 - (1 - k) ** 2, 0, 1))  # a round foot: a quarter ellipse
    taper = np.clip(1 - (s - widest) / (point - widest), 0, 1) ** 1.5  # to a point, its sides drawn in: a lick, not a cone
    half = half_max * grow * np.where(s < widest, 1.0, taper)
    d = np.abs(u - 0.5) / np.maximum(half, 1e-5)
    alpha = (1 - smooth(edge, 1.0, d)) * smooth(0, 0.03, s)  # soft across and round its foot
    alpha *= 1 - 0.55 * smooth(point * 0.72, point, s)  # its point thins to air
    shade = 1 - 0.18 * smooth(0.25, 1.0, d)  # a little deeper toward the edge: volume, never a line
    img = np.concatenate([np.repeat(shade[..., None], 3, -1), alpha[..., None]], -1).astype(np.float32)
    return img.reshape(H, SS, W, SS, 4).mean(axis=(1, 3))[::-1]  # stored tip-up: the tip on the top row


def write_rgba(img, path):
    h, w, _ = img.shape
    data = (np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8).tobytes()
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgba", "-s", f"{w}x{h}", "-i", "-",
                    "-pix_fmt", "rgba", str(path)], input=data, check=True)


def main():
    if sys.argv[1:2] == ["--pictures"]:
        for name, img in (("fx_lick_Flame", lick_picture()), ("fx_lick_Soft", soft_picture("fx_lick_Soft")),
                          ("fx_lick_Core", soft_picture("fx_lick_Core"))):
            path = PICTURES / f"{name}.png"
            write_rgba(img, path)
            print("wrote", path.relative_to(ROOT).as_posix())
        return
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else OUT
    out.mkdir(parents=True, exist_ok=True)
    data = burn()
    path = out / "StateBurn.rows.json"
    path.write_bytes((compact(data) + "\n").encode("utf-8"))
    keys = sum(len(k) for r in data["Rows"].values() for k in r["Tracks"].values())
    print(f"wrote {path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else path}: "
          f"{len(data['Rows'])} rows, {keys} keys, {path.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
